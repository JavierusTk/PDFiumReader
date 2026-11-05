program PDFiumReader;

uses
  Forms,
  ExecutelibPDFium in 'ExecutelibPDFium.pas',
  PDFiumFrame in 'PDFiumFrame.pas' {PDFiumFrame: TFrame},
  Main in 'Main.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
//  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
