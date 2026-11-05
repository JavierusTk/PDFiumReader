unit Main;

{
   PDF viewer using libPDFium.dll (c)2017-2018 by Execute SARL
   http://www.execute.fr
   https://github.com/tothpaul/PDFiumReader


}
interface

uses
  Windows, Messages, ShellAPI,

  SysUtils, Variants, Classes,

  Graphics, Controls, Forms, Dialogs, Menus, ExtCtrls,

  PDFiumFrame,  StdCtrls, Buttons, StdCtrlsMax, EnhancedControls;

type
  TMainForm = class(TForm)
    PDFium: TPDFiumFrame;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Open1: TMenuItem;
    N1: TMenuItem;
    Quit1: TMenuItem;
    pnButtons: TPanel;
    btZPlus: TSpeedButtonMax;
    btZMinus: TSpeedButtonMax;
    btOpen: TSpeedButtonMax;
    pbZoom: TSpeedButtonMax;
    ppZoom: TPopupMenu;
    N101: TMenuItem;
    N251: TMenuItem;
    N501: TMenuItem;
    N1001: TMenuItem;
    N1002: TMenuItem;
    N1251: TMenuItem;
    N1501: TMenuItem;
    N2001: TMenuItem;
    N4001: TMenuItem;
    N8001: TMenuItem;
    N16001: TMenuItem;
    N24001: TMenuItem;
    N32001: TMenuItem;
    N64001: TMenuItem;
    N2: TMenuItem;
    mnActualSize: TMenuItem;
    mnFitWidth: TMenuItem;
    mnPageLevel: TMenuItem;
    btPageWidth: TSpeedButtonMax;
    btFullPage: TSpeedButtonMax;
    btActualSize: TSpeedButtonMax;
    btAbout: TSpeedButtonMax;
    pnPageNav: TPanel;
    btFirstPage: TSpeedButtonMax;
    btPrevPage: TSpeedButtonMax;
    lbPageInfo: TLabel;
    btNextPage: TSpeedButtonMax;
    btLastPage: TSpeedButtonMax;
    edPageNumber: TEdit;
    btGoToPage: TSpeedButtonMax;
    pnSearch: TPanel;
    edSearchText: TEdit;
    btnBuscar: TSpeedButtonMax;
    btFindNext: TSpeedButtonMax;
    btFindPrev: TSpeedButtonMax;
    lbSearchInfo: TLabel;
    btHighlight: TSpeedButtonMax;
    btClearHighlights: TSpeedButtonMax;
    procedure Open1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonMouseLeave(Sender: TObject);
    procedure ButtonMouseEnter(Sender: TObject);
//    procedure pbZoomPaint(Sender: TObject);
    procedure ppZoomPopup(Sender: TObject);
    procedure btZPlusClick(Sender: TObject);
    procedure MenuZoomClick(Sender: TObject);
    procedure mnPageLevelClick(Sender: TObject);
    procedure mnFitWidthClick(Sender: TObject);
    procedure PDFiumResize(Sender: TObject);
    procedure mnActualSizeClick(Sender: TObject);
    procedure btAboutClick(Sender: TObject);
    procedure pbZoomClick(Sender: TObject);
    procedure btFirstPageClick(Sender: TObject);
    procedure btPrevPageClick(Sender: TObject);
    procedure btNextPageClick(Sender: TObject);
    procedure btLastPageClick(Sender: TObject);
    procedure btGoToPageClick(Sender: TObject);
    procedure PDFiumPageChanged(Sender: TObject);
    procedure UpdatePageInfo;
    procedure btnBuscarClick(Sender: TObject);
    procedure btFindNextClick(Sender: TObject);
    procedure btFindPrevClick(Sender: TObject);
    procedure btHighlightClick(Sender: TObject);
    procedure btClearHighlightsClick(Sender: TObject);
    procedure edSearchTextKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { D�clarations priv�es }
//    FButtons  : TBitmap;
//    FFocus    : TPaintBox;
//    procedure CreateButtons;
  public
    { D�clarations publiques }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}


resourcestring
  sPDFFiler  = 'Adobe PDF files (*.pdf)|*.pdf';
  sPDFPrompt = 'Open';

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Application.Title := Caption;
//  FButtons := TBitmap.Create;
//  CreateButtons;
  KeyPreview := True; // Enable form-level keyboard handling
  PDFium.OnPageChanged := PDFiumPageChanged; // Connect page change event
  UpdatePageInfo;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
//  FButtons.Free;
end;

procedure TMainForm.MenuZoomClick(Sender: TObject);
begin
  PDFium.ZoomMode := zmCustom;
  PDFium.Zoom := TComponent(Sender).Tag;
end;

procedure TMainForm.mnActualSizeClick(Sender: TObject);
begin
  PDFium.ZoomMode := zmCustom;
  PDFium.Zoom := 100;
end;

procedure TMainForm.mnFitWidthClick(Sender: TObject);
begin
  PDFium.ZoomMode := zmPageWidth;
end;

procedure TMainForm.mnPageLevelClick(Sender: TObject);
begin
  PDFium.ZoomMode := zmPageLevel;
end;

//procedure TMainForm.ButtonPaint(Sender: TObject);
//var
//  D, S: TRect;
//  I: Integer;
//begin
//  D := TPaintBox(Sender).ClientRect;
//  S := TRect.Create(0, 0, 24, 24);
//  I := TPaintBox(Sender).Tag;
//  if (Sender = FFocus) and (Odd(I) = False) then
//    Inc(I);
//  S.Offset(24 * I, 0);
//  with TPaintBox(Sender).Canvas do
//  begin
//    CopyRect(D, FButtons.Canvas, S);
//  end;
//end;

procedure TMainForm.btAboutClick(Sender: TObject);
begin
  ShellExecute(0, nil, 'http://www.execute.fr', nil, nil, SW_SHOW);
end;

procedure TMainForm.btZPlusClick(Sender: TObject);
var
  Zoom : Integer;
  Z1   : Integer;
  Z2   : Integer;
  Zx   : Integer;
  Index: Integer;
begin
  Z1 := 1000;
  Z2 := 640000;
  Zoom := Round(PDFium.Zoom * 100);
  for Index := 0 to ppZoom.Items.count - 1 do
  begin
    Zx := 100 * ppZoom.Items[Index].Tag;
    if Zx <> 0 then
    begin
      if (Zx < Zoom) and (Zx > Z1) then
        Z1 := Zx
      else
      if (Zx > Zoom) and (Zx < Z2) then
        Z2 := Zx;
    end;
  end;
  if Sender = btZPlus then
    Z1 := Z2;
  PDFium.ZoomMode := zmCustom;
  PDFium.Zoom := Z1/100;
  pbZoom.Invalidate;
end;

procedure TMainForm.ButtonMouseEnter(Sender: TObject);
begin
//  if Sender = FFocus then
//    Exit;
//  if FFocus <> nil then
//    FFocus.Invalidate;
//  FFocus := TPaintBox(Sender);
//  if FFocus <> nil then
//    FFocus.Invalidate;
end;

procedure TMainForm.ButtonMouseLeave(Sender: TObject);
begin
//  if FFocus <> nil then
//  begin
//    FFocus.Invalidate;
//    FFocus := nil;
//  end;
end;

//procedure TMainForm.CreateButtons;
//begin
//  FButtons.PixelFormat := pf32Bit;
//  FButtons.Width:=2 * 2 * 7 * 24;
//  FButtons.Height:=2 * 24;
//  with FButtons.Canvas do begin
//    Brush.Color := clBtnFace;
//    FillRect(Rect(0, 0, FButtons.Width, FButtons.Height));
//
//    Pen.Width := 4;
//    DrawButtons( 0, $6F6F6F);
//    DrawButtons(48, $C87521);
//  end;
////  FButtons.SaveToFile('BUTTONS48.BMP');
//  AntiAliaze(FButtons);
//  with FButtons.Canvas do
//  begin
//    Pen.Width := 1;
//    FixButtons( 0, $6F6F6F);
//    FixButtons(24, $C87521);
//  end;
////  FButtons.SaveToFile('BUTTONS24.BMP');
//end;

function PromptForFileName(var Filename:string;A,B:string):boolean;
begin
  result:=InputQuery(A,B,Filename);
end;

procedure TMainForm.Open1Click(Sender: TObject);
var
  Str: string;
begin
  Str := '';
  if PromptForFileName(Str, sPDFFiler, sPDFPrompt) then
  begin
    PDFium.LoadFromFile(Str);
    PDFium.SetFocus();
    Caption := ExtractFileName(Str) + ' - ' + Application.Title;
    UpdatePageInfo;
  end;
end;


//procedure TMainForm.pbZoomPaint(Sender: TObject);
//var
//  Str: string;
//  R  : TRect;
//begin
//  R := pbZoom.ClientRect;
//  with pbZoom.Canvas do
//  begin
//    Pen.Color := $CBCBCB;
//    Brush.Color := clWhite;
//    Rectangle(R);
//    if FFocus = Sender then
//    begin
//      Pen.Color := $D28E4A;
//      Brush.Color := $C87521;
//    end else begin
//      Pen.Color := $8A8A8A;
//      Brush.Color := $6F6F6F;
//    end;
//    Arrow(60, 12);
//    Dec(R.Right, 24);
//    Str := FloatToStrF(PDFium.Zoom, TFloatFormat.ffFixed, 18, 0) + '%';
//    Brush.Color := clWhite;
//    Font.Color := $4D4D4D;
//    TextRect(R, Str, [TTextFormats.tfSingleLine, TTextFormats.tfCenter, TTextFormats.tfVerticalCenter]);
//  end;
//end;

procedure TMainForm.PDFiumResize(Sender: TObject);
begin
  btPageWidth.Tag := 6 + Ord(PDFium.ZoomMode = zmPageWidth);
  btFullPage.Tag := 8 + Ord(PDFium.ZoomMode = zmPageLevel);
  btActualSize.Tag := 10 + Ord((PDFium.ZoomMode = zmCustom) and (Round(PDFium.Zoom * 100) = 10000));
  pnButtons.Invalidate;
end;

procedure TMainForm.ppZoomPopup(Sender: TObject);
var
  Zoom : Integer;
  Index: Integer;
begin
  Zoom := Round(PDFium.Zoom * 100);
  for Index := 0 to ppZoom.Items.Count - 1 do
  begin
    ppZoom.Items[Index].Checked := (PDFium.ZoomMode = zmCustom) and (ppZoom.Items[Index].Tag * 100 = Zoom);
  end;
  mnActualSize.Checked := (PDFium.ZoomMode = zmCustom) and (Zoom = 10000);
  mnPageLevel.Checked := PDFium.ZoomMode = zmPageLevel;
  mnFitWidth.Checked := PDFium.ZoomMode = zmPageWidth;
end;

procedure TMainForm.pbZoomClick(Sender: TObject);
var
  p: TPoint;
begin
    p.x := pbZoom.Left;
    p.y := pbZoom.Top+pbZoom.Height;
    p := pbZoom.ClientToScreen(p);
    ppZoom.Popup(p.x, p.y);
end;

procedure TMainForm.btFirstPageClick(Sender: TObject);
begin
  if PDFium.PageCount > 0 then
    PDFium.GoToPage(0);
end;

procedure TMainForm.btPrevPageClick(Sender: TObject);
begin
  if PDFium.PageIndex > 0 then
    PDFium.GoToPage(PDFium.PageIndex - 1);
end;

procedure TMainForm.btNextPageClick(Sender: TObject);
begin
  if PDFium.PageIndex < PDFium.PageCount - 1 then
    PDFium.GoToPage(PDFium.PageIndex + 1);
end;

procedure TMainForm.btLastPageClick(Sender: TObject);
begin
  if PDFium.PageCount > 0 then
    PDFium.GoToPage(PDFium.PageCount - 1);
end;

procedure TMainForm.btGoToPageClick(Sender: TObject);
var
  PageNum: Integer;
begin
  if TryStrToInt(edPageNumber.Text, PageNum) then
  begin
    Dec(PageNum); // Convert from 1-based to 0-based
    if (PageNum >= 0) and (PageNum < PDFium.PageCount) then
      PDFium.GoToPage(PageNum);
  end;
end;

procedure TMainForm.PDFiumPageChanged(Sender: TObject);
begin
  UpdatePageInfo;
end;

procedure TMainForm.UpdatePageInfo;
begin
  if PDFium.PageCount > 0 then
  begin
    lbPageInfo.Caption := Format('Page %d of %d', [PDFium.PageIndex + 1, PDFium.PageCount]);
    edPageNumber.Text := IntToStr(PDFium.PageIndex + 1);
    btFirstPage.Enabled := PDFium.PageIndex > 0;
    btPrevPage.Enabled := PDFium.PageIndex > 0;
    btNextPage.Enabled := PDFium.PageIndex < PDFium.PageCount - 1;
    btLastPage.Enabled := PDFium.PageIndex < PDFium.PageCount - 1;
  end
  else
  begin
    lbPageInfo.Caption := 'No document loaded';
    edPageNumber.Text := '';
    btFirstPage.Enabled := False;
    btPrevPage.Enabled := False;
    btNextPage.Enabled := False;
    btLastPage.Enabled := False;
  end;
end;

procedure TMainForm.btnBuscarClick(Sender: TObject);
var
  Count: Integer;
begin
  if edSearchText.Text <> '' then
  begin
    Count := PDFium.SearchText(edSearchText.Text, False);
    if Count > 0 then
      lbSearchInfo.Caption := Format('%d matches found', [Count])
    else
      lbSearchInfo.Caption := 'No matches found';

    btFindNext.Enabled := Count > 0;
    btFindPrev.Enabled := Count > 0;
  end;
end;

procedure TMainForm.btFindNextClick(Sender: TObject);
begin
  PDFium.FindNext;
end;

procedure TMainForm.btFindPrevClick(Sender: TObject);
begin
  PDFium.FindPrevious;
end;

procedure TMainForm.btHighlightClick(Sender: TObject);
begin
  PDFium.AddHighlight(clYellow);
end;

procedure TMainForm.btClearHighlightsClick(Sender: TObject);
begin
  PDFium.ClearAllHighlights;
  PDFium.ClearWordHighlights;
  PDFium.ClearSearchResults;
  lbSearchInfo.Caption := '';
end;

procedure TMainForm.edSearchTextKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    btnBuscarClick(Sender);
    Key := 0;
  end;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    // Ctrl+F: Search
    Ord('F'):
      if ssCtrl in Shift then
      begin
        if edSearchText.CanFocus then
          edSearchText.SetFocus;
        Key := 0;
      end;

    // F3: Find Next
    VK_F3:
      begin
        if ssShift in Shift then
          btFindPrevClick(Sender)
        else
          btFindNextClick(Sender);
        Key := 0;
      end;

    // Ctrl+G: Go to page
    Ord('G'):
      if ssCtrl in Shift then
      begin
        if edPageNumber.CanFocus then
          edPageNumber.SetFocus;
        Key := 0;
      end;

    // Ctrl+H: Highlight selected text
    Ord('H'):
      if ssCtrl in Shift then
      begin
        btHighlightClick(Sender);
        Key := 0;
      end;

    // Page Down: Next page
    VK_NEXT:
      if not (ssCtrl in Shift) then
      begin
        btNextPageClick(Sender);
        Key := 0;
      end;

    // Page Up: Previous page
    VK_PRIOR:
      if not (ssCtrl in Shift) then
      begin
        btPrevPageClick(Sender);
        Key := 0;
      end;

    // Home: First page
    VK_HOME:
      if ssCtrl in Shift then
      begin
        btFirstPageClick(Sender);
        Key := 0;
      end;

    // End: Last page
    VK_END:
      if ssCtrl in Shift then
      begin
        btLastPageClick(Sender);
        Key := 0;
      end;
  end;
end;

end.
