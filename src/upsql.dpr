program upsql;
{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {frmUpdate},
  uTable in 'updata\uTable.pas',
  uView in 'updata\uView.pas',
  uProcdure in 'updata\uProcdure.pas',
  uTrigger in 'updata\uTrigger.pas',
  uFunction in 'updata\uFunction.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmUpdate, frmUpdate);
  Application.Run;
end.
