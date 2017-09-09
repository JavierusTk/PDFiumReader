unit PDFium.Frame;

{
   PDF viewer using PDFium.dll (c)2017 by Execute SARL
   http://www.execute.fr
   https://github.com/tothpaul/Delphi

   inspired by PdfiumLib
   https://github.com/ahausladen/PdfiumLib

   2017-09-09  v1.0

}

interface

uses
  Winapi.Windows, Winapi.Messages,

  System.SysUtils, System.Variants, System.Classes, System.Math,

  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,

  PDFium.Wrapper, Vcl.ExtCtrls;

const
  PAGE_MARGIN = 5;  // pixels

type
  TZoomMode = (
    zmCustom,
    zmActualSize,
    zmPageLevel,
    zmPageWidth
  );

  TPDFiumFrame = class(TFrame)
  private
    { Déclarations privées }
    type
      // One point is 1/72 inch (around 0.3528 mm).
      TPointsSize = record
        cx : Double;
        cy : Double;
      end;

      TRectD = record
        Left   : Double;
        Top    : Double;
        Right  : Double;
        Bottom : Double;
      end;

      TPDFPage = class
        Index    : Integer;
        Handle   : HPDFPage;
        Top      : Double;
        Rect     : TRect;
        Text     : HPDFTextPage;
        NoText   : Boolean;
        Visible  : Integer;
        SelStart : Integer;
        SelStop  : Integer;
        Selection: TArray<TRectD>;
        destructor Destroy; override;
        function HasText: Boolean;
        function CharIndex(x, y, distance: Integer): Integer;
        function CharCount: Integer;
        function Select(Start: Integer): Boolean;
        function SelectTo(Stop: Integer): Boolean;
        function ClearSelection: Boolean;
        procedure DrawSelection(DC, BMP: HDC; const Blend: TBlendFunction; const Client: TRect);
      end;

  private
    FDocument : HPDFDocument;
    FError    : Integer;
    FPageCount: Integer;
    FPageSize : TArray<TPointsSize>;
    FTotalSize: TPointsSize;
    FPages    : TList;
    FReload   : Boolean;
    FPageIndex: Integer;
    FZoom     : Single;
    FZoomMode : TZoomMode;
    FStatus   : TLabel;
    FCurPage  : TPDFPage;
    FSelPage  : TPDFPage;
    FSelStart : Integer;
    FSelBmp   : TBitmap;
    FCharIndex: Integer;
    FCharBox  : TRectD;
    procedure SetDocument(Value: HPDFDocument);
    procedure SetPageCount(Value: Integer);
    procedure SetScrollSize;
    procedure SetZoom(Value: Single);
    procedure SetZoomMode(Value: TZoomMode);
    procedure AdjustZoom;
    property _Document: HPDFDocument read FDocument write SetDocument;
    procedure ClearPages;
    function GetPage(PageIndex: Integer): TPDFPage;
    function GetPageAt(const p: TPoint): TPDFPage;
    procedure LoadVisiblePages;
    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMHScroll(var Message: TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
  protected
    procedure PaintWindow(DC: HDC); override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    { Déclarations publiques }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadFromMemory(APointer: Pointer; ASize: Integer);
    procedure LoadFromStream(AStream: TStream);
    procedure LoadFromFile(const AFileName: string);
    procedure ClearSelection;
    function PageLevelZoom: Single;
    function PageWidthZoom: Single;
    property Document: HPDFDocument read FDocument;
    property PageIndex: Integer read FPageIndex;
    property PageCount: Integer read FPageCount;
    property Zoom: Single read FZoom write SetZoom;
    property ZoomMode: TZoomMode read FZoomMode write SetZoomMode;
  end;

implementation

{$R *.dfm}

resourcestring
  sUnableToLoadPDFium = 'Unable to load PDFium.dll';

{ TPDFiumFrame.TPDFPage }

function TPDFiumFrame.TPDFPage.HasText: Boolean;
begin
  if (Text = 0) and (NoText = False) then
  begin
    Text := FPDFText_LoadPage(Handle);
    NoText := Text = 0;
  end;
  Result := not NoText;
end;

function TPDFiumFrame.TPDFPage.CharCount: Integer;
begin
  if HasText then
    Result := FPDFText_CountChars(Text)
  else
    Result := 0;
end;

function TPDFiumFrame.TPDFPage.CharIndex(x, y, distance: Integer): Integer;
var
  Pos: TPointsSize;
begin
  if HasText = False then
    Exit(-1);
  FPDF_DeviceToPage(Handle, Rect.Left, Rect.Top, Rect.Width, Rect.Height, 0, x, y, Pos.cx, Pos.cy);
  Result := FPDFText_GetCharIndexAtPos(Text, Pos.cx, Pos.cy, distance, distance)
end;

function TPDFiumFrame.TPDFPage.ClearSelection: Boolean;
begin
  Result := Selection <> nil;
  if Result then
  begin
    Selection := nil;
    SelStart := 0;
    SelStop := 0;
  end;
end;

destructor TPDFiumFrame.TPDFPage.Destroy;
begin
  if Text <> 0 then
    FPDFText_ClosePage(Text);
  FPDF_ClosePage(Handle);
  inherited;
end;

procedure TPDFiumFrame.TPDFPage.DrawSelection(DC, BMP: HDC; const Blend: TBlendFunction; const Client: TRect);
var
  Index: Integer;
  R: TRect;
begin
  for Index := 0 to Length(Selection) - 1 do
  begin
    with Selection[Index] do
    begin
      FPDF_PageToDevice(Handle, Rect.Left, Rect.Top, Rect.Width, Rect.Height, 0, Left, Top, R.Left, R.Top);
      FPDF_PageToDevice(Handle, Rect.Left, Rect.Top, Rect.Width, Rect.Height, 0, Right, Bottom, R.Right, R.Bottom);
    end;
    if Client.IntersectsWith(R) then
      AlphaBlend(DC, R.Left, R.Top, R.Width, R.Height, BMP, 0, 0, 100, 50, Blend);
  end;
end;

function TPDFiumFrame.TPDFPage.Select(Start: Integer): Boolean;
begin
  Result := Selection <> nil;
  if (HasText = False) or (Start < 0) then
  begin
    Start := 0;
  end;
  SelStart := Start;
  SelStop := SelStart;
  Selection := nil;
end;

function TPDFiumFrame.TPDFPage.SelectTo(Stop: Integer): Boolean;
var
  SelLen: Integer;
  Start : Integer;
  Count : Integer;
  Index : Integer;
begin
  if Stop < 0 then
    Exit(False);

  if Stop > SelStart then
    Inc(Stop); // add one char

  if Stop = SelStop then
    Exit(False);
  Result := True;

  SelStop := Stop;
  SelLen := SelStop - SelStart;

  if SelLen = 0 then
    Selection := nil
  else begin
    if SelLen > 0 then
      Start := SelStart
    else begin
      Start := SelStop;
      SelLen := -SelLen;
    end;
    Count := FPDFText_CountRects(Text, Start, SelLen);
    SetLength(Selection, Count);
    for Index := 0 to Count - 1 do
    begin
      with Selection[Index] do
        FPDFText_GetRect(Text, Index, Left, Top, Right, Bottom);
    end;
  end;

end;

{ TPDFiumFrame }

constructor TPDFiumFrame.Create(AOwner: TComponent);
begin
  inherited;
  FZoom := 100;
  FPageIndex := -1;

  FSelBmp := TBitmap.Create;
  FSelBmp.Canvas.Brush.Color := RGB(50, 142, 254);
  FSelBmp.SetSize(100, 50);

  FPages := TList.Create;
  try
    FPDF_InitLibrary;
  except
    FStatus := TLabel.Create(Self);
    FStatus.Align := alClient;
    FStatus.Parent := Self;
    FStatus.Alignment := taCenter;
    FStatus.Layout := tlCenter;
    FStatus.Caption := sUnableToLoadPDFium;
  end;
end;

destructor TPDFiumFrame.Destroy;
begin
  _Document := 0;
  FPages.Free;
  inherited;
end;

function TPDFiumFrame.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  FReload := True;
  VertScrollBar.Position := VertScrollBar.Position - WheelDelta;
  Result := True;
end;

procedure TPDFiumFrame.LoadFromFile(const AFileName: string);
var
  AnsiName: AnsiString;
begin
  AnsiName := AnsiString(AFileName);
  _Document := FPDF_LoadDocument(PAnsiChar(AnsiName), nil);
end;

procedure TPDFiumFrame.LoadFromMemory(APointer: Pointer; ASize: Integer);
begin
  _Document := FPDF_LoadMemDocument(APointer, ASize, nil);
end;

procedure TPDFiumFrame.LoadFromStream(AStream: TStream);
var
  Stream: TCustomMemoryStream;
begin
  if AStream is TCustomMemoryStream then
    Stream := TCustomMemoryStream(AStream)
  else begin
    Stream := TMemoryStream.Create;
    Stream.CopyFrom(AStream, AStream.Size - AStream.Position);
  end;
  try
    LoadFromMemory(Stream.Memory, Stream.Size);
  finally
    if Stream <> AStream then
      Stream.Free;
  end;
end;

procedure TPDFiumFrame.SetDocument(Value: HPDFDocument);
begin
  ClearPages;
  if FDocument <> 0 then
    FPDF_CloseDocument(FDocument);
  FDocument := Value;
  if FDocument = 0 then
    FError := FPDF_GetLastError
  else
    SetPageCount(FPDF_GetPageCount(FDocument));
  FReload := True;
  Invalidate;
end;

procedure TPDFiumFrame.SetPageCount(Value: Integer);
var
  Index: Integer;
begin
  FTotalSize.cx := 0;
  FTotalSize.cy := 0;
  FPageCount := Value;
  if FPageCount > 0 then
  begin
    SetLength(FPageSize, FPageCount);
    for Index := 0 to FPageCount - 1 do
      with FPageSize[Index] do
      begin
        FPDF_GetPageSizeByIndex(FDocument, Index, cx, cy);
        if cx > FTotalSize.cx then
          FTotalSize.cx := cx;
        FTotalSize.cy := FTotalSize.cy + cy;
      end;
  end;
  HorzScrollBar.Position := 0;
  VertScrollBar.Position := 0;
  SetScrollSize;
end;

procedure TPDFiumFrame.SetScrollSize;
var
  Scale: Single;
begin
  Scale := FZoom / 100 * Screen.PixelsPerInch / 72;
  HorzScrollBar.Range := Round(FTotalSize.cx * Scale) + PAGE_MARGIN * 2;
  VertScrollBar.Range := Round(FTotalSize.cy * Scale) + PAGE_MARGIN * (FPageCount + 1);
end;

procedure TPDFiumFrame.SetZoom(Value: Single);
begin
  if Value < 0.65 then
    Value := 0.65;
  if Value > 6400 then
    Value := 6400;
  FZoom := Value;
  if FDocument <> 0 then
  begin
    SetScrollSize;
    FReload := True;
    Invalidate;
  end;
  if Assigned(OnResize) then
    OnResize(Self);
end;

procedure TPDFiumFrame.SetZoomMode(Value: TZoomMode);
begin
  FZoomMode := Value;
  AdjustZoom;
end;

procedure TPDFiumFrame.AdjustZoom;
begin
  case FZoomMode of
    zmCustom    : Exit;
    zmActualSize: Zoom := 100;
    zmPageLevel : Zoom := PageLevelZoom;
    zmPageWidth : Zoom := PageWidthZoom;
  end;
end;

procedure TPDFiumFrame.ClearPages;
var
  Index: Integer;
begin
  for Index := 0 to FPages.Count - 1 do
    TPDFPage(FPages[Index]).Free;
  FPages.Clear;
end;

procedure TPDFiumFrame.ClearSelection;
var
  Clear: Boolean;
  Index: Integer;
  Page : TPDFPage;
begin
  Clear := False;
  for Index := 0 to FPages.Count - 1 do
  begin
    Page := FPages[Index];
    if Page.ClearSelection then
      Clear := True;
  end;
  if Clear then
    Invalidate;
end;

function TPDFiumFrame.GetPage(PageIndex: Integer): TPDFPage;
var
  Index: Integer;
begin
  for Index := 0 to FPages.Count - 1 do
  begin
    Result := FPages[Index];
    if Result.Index = PageIndex then
      Exit;
  end;
  Result := TPDFPage.Create;
  FPages.Add(Result);
  Result.Index := PageIndex;
  Result.Handle := FPDF_LoadPage(FDocument, PageIndex);
end;

function TPDFiumFrame.GetPageAt(const p: TPoint): TPDFPage;
var
  Index: Integer;
begin
  for Index := 0 to FPages.Count - 1 do
  begin
    Result := FPages[Index];
    if (Result.Visible > 0) and (Result.Rect.Contains(p)) then
      Exit;
  end;
  Result := nil;
end;

procedure TPDFiumFrame.LoadVisiblePages;
var
  Index : Integer;
  Page  : TPDFPage;
  Top   : Double;
  Scale : Double;
  Client: TRect;
  Rect  : TRect;
  Marge : Integer;
begin
  FPageIndex := -1;
  FCurPage := nil;

  for Index := 0 to FPages.Count - 1 do
  begin
    Page := FPages[Index];
    if Page.Selection = nil then
      Dec(Page.Visible)
    else
      Page.Visible := 0;
  end;

  Client := ClientRect;
  Top := 0;
  Marge := PAGE_MARGIN;
  Scale := FZoom / 100 * Screen.PixelsPerInch / 72;
  for Index := 0 to FPageCount - 1 do
  begin
  // compute page position
    Rect.Top := Round(Top * Scale) + Marge - VertScrollBar.Position;
    Rect.Left := PAGE_MARGIN + Round((FTotalSize.cx - FPageSize[Index].cx) / 2 * Scale) - HorzScrollBar.Position;
    Rect.Width := Round(FPageSize[Index].cx * Scale);
    Rect.Height := Round(FPageSize[Index].cy * Scale);
    if Rect.Width < Client.Width - 2 * PAGE_MARGIN then
      Rect.Offset((Client.Width - Rect.Width) div 2 - Rect.Left, 0);
  // visibility test
    if Rect.IntersectsWith(Client) then
    begin
      if FPageIndex < 0 then
        FPageIndex := Index;
      Page := GetPage(Index);
      Page.Rect := Rect;
      Page.Visible := 1;
    end;
  // don't go below client area
    if Rect.Top > Client.Bottom then
      Break;
  // next page top position
    Top := Top + FPageSize[Index].cy;
    Inc(Marge, PAGE_MARGIN);
  end;

  // release any page that was not visibile for the last 5 paint events
  for Index := FPages.Count - 1 downto 0 do
  begin
    Page := FPages[Index];
    if Page.Visible < -5 then
    begin
      Page.Free;
      FPages.Delete(Index);
    end;
  end;
end;


procedure TPDFiumFrame.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  i: Integer;
begin
  inherited;
  SetFocus();
  if FCurPage <> nil then
  begin
    ClearSelection;
    i := FCurPage.CharIndex(x, y, 5);
    if i >= 0 then
    begin
      FSelPage := FCurPage; // selection mode
      FSelStart := FSelPage.Index; // page index where the selections start
      FSelPage.Select(i); // set SelStart
    end;
  end;
end;

procedure TPDFiumFrame.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  i: Integer;
begin
  inherited;

  p.x := x;
  p.y := y;

  // page under the cursor
  if (FCurPage = nil) or (FCurPage.Rect.Contains(p) = False) then
    FCurPage := GetPageAt(p);

  // there's a page under the cursor
  if FCurPage = nil then
    i := -1
  else begin
    if FCurPage = FSelPage then // in selection mode, allows more flexible search
      i := 65535
    else
      i := 5;
    i := FCurPage.CharIndex(x, y, i); // character under the cursor in the current page
  end;

  if i <> FCharIndex then
  begin
    FCharIndex := i;
    if FCharIndex >= 0 then
      FPDFText_GetCharBox(FCurPage.Text, i, FCharBox.Left, FCharBox.Right, FCharBox.Bottom, FCharBox.Top);
    Invalidate;
  end;

  // selecting
  if FSelPage <> nil then
  begin
    // move the mouse inside the same page
    if FSelPage = FCurPage then
    begin
      if FSelPage.SelectTo(i) then // selStop
        Invalidate;
      Exit; // done
    end;
    // the mouse is outside the page
    if y < FSelPage.Rect.Top then // above
    begin
      if FSelPage.Index > FSelStart then // remove selection
        FSelPage.ClearSelection
      else
        FSelPage.SelectTo(0) // or extend it to the top of the page
    end else begin  // below
      if FSelPage.Index < FSelStart then // remove selection
        FSelPage.ClearSelection
      else
        FSelPage.SelectTo(FSelPage.CharCount); // extend to the bottom of the page
    end;
    Invalidate;
    // mouse over an other page with a character found
    if (FCurPage <> nil) and (i >= 0) then
    begin
      FSelPage := FCurPage; // change selected page
      if FSelPage.Selection = nil then // new page
      begin
        if FSelPage.Index > FSelStart then // from the top ...
          FSelPage.Select(0)
        else
          FSelPage.Select(FSelPAge.CharCount) // or from the bottom ...
        end;
      FSelPage.SelectTo(i); // ... to the active character
    end;
    Exit;
  end;

  // no selection, change cursor as needed
  if i = -1 then
  begin
    Cursor := crDefault;
  end else begin
    Cursor := crIBeam;
  end;
end;

procedure TPDFiumFrame.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  FSelPage := nil; // exit selection mode
end;

procedure TPDFiumFrame.WMHScroll(var Message: TWMHScroll);
begin
  FReload := True;
  inherited;
end;

procedure TPDFiumFrame.WMVScroll(var Message: TWMVScroll);
begin
  FReload := True;
  inherited;
end;

procedure TPDFiumFrame.WMPaint(var Msg: TWMPaint);
begin
  ControlState := ControlState + [csCustomPaint];
  inherited;
  ControlState := ControlState - [csCustomPaint];
end;

function TPDFiumFrame.PageLevelZoom: Single;
var
  Scale : Single;
  Z1, Z2: Single;
begin
  if FPageIndex < 0 then
    Exit(100);
  Scale := 72 / Screen.PixelsPerInch;
  Z1 := (ClientWidth  - 2 * PAGE_MARGIN) * Scale / FPageSize[FPageIndex].cx;
  Z2 := (ClientHeight - 2 * PAGE_MARGIN) * Scale / FPageSize[FPageIndex].cy;
  if Z1 > Z2 then
    Z1 := Z2;
  Result := 100 * Z1;
end;

function TPDFiumFrame.PageWidthZoom: Single;
var
  Scale : Single;
begin
  if FPageIndex < 0 then
    Exit(100);
  Scale := 72 / Screen.PixelsPerInch;
  Result := 100 * (ClientWidth  - 2 * PAGE_MARGIN) * Scale / FPageSize[FPageIndex].cx;
end;

procedure TPDFiumFrame.PaintWindow(DC: HDC);
var
  Index : Integer;
  Page  : TPDFPage;
  Client: TRect;
  WHITE : HBrush;
  SelDC : HDC;
  Blend : TBlendFunction;
begin
// gray background
  FillRect(DC, ClientRect, GetStockObject(GRAY_BRUSH));
// nothing to render
  if FPageCount = 0 then
    Exit;
// check visibility
  if FReload or (FPages.Count = 0) then
  begin
    LoadVisiblePages;
    FReload := False;
  end;
// page background
  WHITE := GetStockObject(WHITE_BRUSH);

  SelDC := FSelBMP.Canvas.Handle;

  Blend.BlendOp := AC_SRC_OVER;
  Blend.BlendFlags := 0;
  Blend.SourceConstantAlpha := 127;
  Blend.AlphaFormat := 0;

  Client := ClientRect;

  for Index := 0 to FPages.Count - 1 do
  begin
    Page := FPages[Index];
    if Page.Visible > 0 then
    begin
      FillRect(DC, Page.Rect, WHITE);
      FPDF_RenderPage(DC, Page.Handle, Page.Rect.Left, Page.Rect.Top, Page.Rect.Width, Page.Rect.Height, 0, 0);
      Page.DrawSelection(DC, SelDC, Blend, Client);
    end;
  end;

  if (FCurPage <> nil) and (FCharIndex >= 0) then
  begin
    with FCurPage do
    begin
      FPDF_PageToDevice(Handle, Rect.Left, Rect.Top, Rect.Width, Rect.Height, 0, FCharBox.Left, FCharBox.Top, Client.Left, Client.Top);
      FPDF_PageToDevice(Handle, Rect.Left, Rect.Top, Rect.Width, Rect.Height, 0, FCharBox.Right, FCharBox.Bottom, Client.Right, Client.Bottom);
    end;
    DrawFocusRect(DC, Client);
  end;
end;

procedure TPDFiumFrame.Resize;
begin
  inherited;
  AdjustZoom;
  FReload := True;
// repaing
  Invalidate;
end;

end.
