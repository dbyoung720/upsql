unit Unit1;

interface

uses Winapi.Windows, Winapi.ShellAPI, System.SysUtils, System.StrUtils, System.Classes, System.Types, System.IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Data.Win.ADODB, Vcl.StdCtrls, Vcl.Buttons;

type
  TfrmUpdate = class(TForm)
    con1: TADOConnection;
    qry1: TADOQuery;
    qry2: TADOQuery;
    qry3: TADOQuery;
    lbl1: TLabel;
    cbbLibrary: TComboBox;
    lbl2: TLabel;
    edtBakFileName: TEdit;
    btnSelect: TSpeedButton;
    dlgOpen1: TOpenDialog;
    btnUpdate: TButton;
    mmoLog: TMemo;
    qry4: TADOQuery;
    procedure FormCreate(Sender: TObject);
    procedure btnSelectClick(Sender: TObject);
    procedure cbbLibraryChange(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
  private
    { �о����п� }
    procedure GetDatabaseLibraryList;
    { ��ȡ��ǰĿ¼���Ƿ������ݿⱸ���ļ� }
    procedure GetDatabaseBackupFile;
    { �µ����ݿ⻹ԭ }
    function RestoreDatabase(const strBakFileName, strDBDataName, strDBLogName: string; var strUpdateDatabaseName: string): Boolean;
    { ɾ����ʱ���������ݿ� }
    procedure DeleteUpdateDataBase(const strDatabaseName: string);
    { ���� }
    procedure CheckTable(const strUpdateDatabaseName: string);
    { �����ͼ }
    procedure CheckView(const strUpdateDatabaseName: string);
    { ��鴥���� }
    procedure CheckTrigger(const strUpdateDatabaseName: string);
    { ���洢���� }
    procedure CheckProc(const strUpdateDatabaseName: string);
    { ����Զ��庯�� }
    procedure CheckFunc(const strUpdateDatabaseName: string);
  public
    { ��־ }
    procedure LogInfo(const strTip: string);
    procedure ShellCommandUpdateFile(const strFileName: string);
  end;

var
  frmUpdate: TfrmUpdate;

implementation

{$R *.dfm}

uses uTable, uView, uProcdure, uTrigger, uFunction;

procedure TfrmUpdate.LogInfo(const strTip: string);
begin
  mmoLog.Lines.Add(Format('%s%s%s', [FormatDateTime('yyyy-MM-dd HH:mm:ss', Now), Char(9), strTip]));
end;

procedure TfrmUpdate.ShellCommandUpdateFile(const strFileName: string);
var
  strDatabaseName: string;
  strServerName  : string;
  strLoginName   : string;
  strLoginPass   : string;
  strCMDFileName : string;
begin
  strDatabaseName := cbbLibrary.Text;
  strServerName   := con1.Properties['Data Source'].Value;
  strLoginName    := con1.Properties['User ID'].Value;
  strLoginPass    := con1.Properties['Password'].Value;
  strCMDFileName  := TPath.GetTempPath + 'update.cmd';

  with TStringList.Create do
  begin
    Add('@echo off');
    Add(Format('sqlcmd -S %s -d %s -U %s -P %s -i "%s"', [strServerName, strDatabaseName, strLoginName, strLoginPass, strFileName]));
    Add('del /a /f /q %0');
    SaveToFile(strCMDFileName);
    free;
  end;
  WinExec(PAnsiChar(AnsiString(strCMDFileName)), SW_HIDE);
end;

procedure TfrmUpdate.btnSelectClick(Sender: TObject);
begin
  if not dlgOpen1.Execute then
    Exit;

  edtBakFileName.Text := dlgOpen1.FileName;
  btnUpdate.Enabled   := (cbbLibrary.ItemIndex <> -1) and (edtBakFileName.Text <> '') and (FileExists(edtBakFileName.Text));
end;

procedure TfrmUpdate.cbbLibraryChange(Sender: TObject);
begin
  btnUpdate.Enabled := (cbbLibrary.ItemIndex <> -1) and (edtBakFileName.Text <> '') and (FileExists(edtBakFileName.Text));
end;

procedure TfrmUpdate.FormCreate(Sender: TObject);
var
  mfiles     : TStringDynArray;
  strFileName: String;
begin
  mfiles := TDirectory.GetFiles(ExtractFilePath(ParamStr(0)), '*.udl');
  if Length(mfiles) <= 0 then
  begin
    Caption := '���ݿ�����---û���ҵ� udl ���ݿ������ļ�';
    Exit;
  end;

  strFileName           := mfiles[0];
  con1.KeepConnection   := True;
  con1.LoginPrompt      := False;
  con1.Provider         := strFileName;
  con1.ConnectionString := 'FILE NAME=' + strFileName;
  try
    con1.Connected := True;
    Caption        := '���ݿ�����---���ݿ����ӳɹ�';
    GetDatabaseLibraryList;
    GetDatabaseBackupFile;
  except
    Caption := '���ݿ�����---���ݿ�����ʧ��';
  end;
end;

{ �о����п� }
procedure TfrmUpdate.GetDatabaseLibraryList;
begin
  qry1.Close;
  qry1.SQL.Clear;
  qry1.SQL.Text := 'select name from master.dbo.sysdatabases where dbid > 4 ORDER BY name';
  qry1.Open;
  if qry1.RecordCount > 0 then
  begin
    qry1.First;
    while not qry1.Eof do
    begin
      cbbLibrary.Items.Add(qry1.Fields[0].AsString);
      qry1.Next;
    end;
    cbbLibrary.ItemIndex := cbbLibrary.Items.IndexOf(con1.Properties['Initial Catalog'].Value);
  end;
end;

{ ��ȡ��ǰĿ¼���Ƿ������ݿⱸ���ļ� }
procedure TfrmUpdate.GetDatabaseBackupFile;
var
  mfiles     : TStringDynArray;
  strFileName: String;
begin
  mfiles := TDirectory.GetFiles(ExtractFilePath(ParamStr(0)), '*.bak');
  if Length(mfiles) <= 0 then
    Exit;

  strFileName         := mfiles[0];
  edtBakFileName.Text := strFileName;
end;

{ ɾ����ʱ���������ݿ� }
procedure TfrmUpdate.DeleteUpdateDataBase(const strDatabaseName: string);
const
  c_strSQL =                                                                      //
    ' use master ' +                                                              //
    '  ' +                                                                        //
    ' declare @v_sql nvarchar(1000) ' +                                           //
    ' declare csr cursor local for select sr='' kill ''+cast(spid as varchar) ' + //
    ' from master..sysprocesses ' +                                               //
    ' where dbid=db_id(%s) ' +                                                    //
    '  ' +                                                                        //
    ' open csr ' +                                                                //
    ' fetch next from csr into @v_sql ' +                                         //
    ' while @@fetch_status=0 ' +                                                  //
    ' begin ' +                                                                   //
    ' exec(@v_sql) ' +                                                            //
    ' fetch next from csr into @v_sql ' +                                         //
    ' end ' +                                                                     //
    ' close cs ' +                                                                //
    ' deallocate csr ' +                                                          //
    ' exec(''drop database %s'') ';
begin
  qry1.Close;
  qry1.SQL.Clear;
  qry1.SQL.Text := Format(c_strSQL, [QuotedStr(strDatabaseName), strDatabaseName]);
  try
    qry1.ExecSQL;
  except
    on E: Exception do
    begin
      LogInfo('ɾ���������ݿ�ʧ�ܡ�ԭ��' + E.Message);
      LogInfo(qry1.SQL.Text);
    end;
  end;
end;

{ �µ����ݿ⻹ԭ }
function TfrmUpdate.RestoreDatabase(const strBakFileName, strDBDataName, strDBLogName: string; var strUpdateDatabaseName: string): Boolean;
const
  c_strSQL =                     //
    'RESTORE DATABASE %s ' +     //
    'FROM DISK = %s ' +          //
    'WITH REPLACE, RECOVERY, ' + //
    'MOVE %s TO %s, ' +          //
    'MOVE %s TO %s ';
var
  strDBPath: string;
begin
  Result := True;

  strDBPath := ExtractFilePath(strBakFileName);
  strDBPath := strDBPath + Ifthen(RightStr(strDBPath, 1) <> '\', '\', '');

  strUpdateDatabaseName := 'Update' + FormatDateTime('yyyyMMdd', Now);
  qry1.Close;
  qry1.SQL.Clear;
  qry1.SQL.Text := Format(c_strSQL,                          //
    [strUpdateDatabaseName,                                  // ���ݿ�����
    QuotedStr(strBakFileName),                               // �µ����ݿⱸ���ļ�
    QuotedStr(strDBDataName),                                // ԭ�е������ļ��߼�����
    QuotedStr(strDBPath + strUpdateDatabaseName + '.mdf'),   // ָ�������ļ�·��
    QuotedStr(strDBLogName),                                 // ԭ�е���־�ļ��߼�����
    QuotedStr(strDBPath + strUpdateDatabaseName + '.ldf')]); // ָ����־�ļ�·��
  try
    qry1.ExecSQL;
  except
    on E: Exception do
    begin
      Result := False;
      LogInfo('��ԭ���ݿ�ʧ�ܡ�ԭ��' + E.Message);
      LogInfo(qry1.SQL.Text);
    end;
  end;
end;

{ ���� }
procedure TfrmUpdate.CheckTable(const strUpdateDatabaseName: string);
begin
  CreateNotExistTable(cbbLibrary.Text, strUpdateDatabaseName); // ���������ڵı�
  DeleteNoNeededTable(cbbLibrary.Text, strUpdateDatabaseName); // ɾ������Ҫ�ı�
  UpdateYesExistTable(cbbLibrary.Text, strUpdateDatabaseName); // �����Ѵ��ڵı�
end;

{ �����ͼ }
procedure TfrmUpdate.CheckView(const strUpdateDatabaseName: string);
begin
  CreateNotExistView(cbbLibrary.Text, strUpdateDatabaseName); // ���������ڵ���ͼ
  DeleteNoNeededView(cbbLibrary.Text, strUpdateDatabaseName); // ɾ������Ҫ����ͼ
  UpdateYesExistView(cbbLibrary.Text, strUpdateDatabaseName); // �����Ѵ��ڵ���ͼ
end;

{ ��鴥���� }
procedure TfrmUpdate.CheckTrigger(const strUpdateDatabaseName: string);
begin
  CreateNotExistTrigger(cbbLibrary.Text, strUpdateDatabaseName); // ���������ڵĴ�����
  DeleteNoNeededTrigger(cbbLibrary.Text, strUpdateDatabaseName); // ɾ������Ҫ�Ĵ�����
  UpdateYesExistTrigger(cbbLibrary.Text, strUpdateDatabaseName); // �����Ѵ��ڵĴ�����
end;

{ ���洢���� }
procedure TfrmUpdate.CheckProc(const strUpdateDatabaseName: string);
begin
  CreateNotExistProc(cbbLibrary.Text, strUpdateDatabaseName); // ���������ڵĴ洢����
  DeleteNoNeededProc(cbbLibrary.Text, strUpdateDatabaseName); // ɾ������Ҫ�Ĵ洢����
  UpdateYesExistProc(cbbLibrary.Text, strUpdateDatabaseName); // �����Ѵ��ڵĴ洢����
end;

{ ����Զ��庯�� }
procedure TfrmUpdate.CheckFunc(const strUpdateDatabaseName: string);
begin
  CreateNotExistFunc(cbbLibrary.Text, strUpdateDatabaseName); // ���������ڵ��Զ��庯��
  DeleteNoNeededFunc(cbbLibrary.Text, strUpdateDatabaseName); // ɾ������Ҫ���Զ��庯��
  UpdateYesExistFunc(cbbLibrary.Text, strUpdateDatabaseName); // �����Ѵ��ڵ��Զ��庯��
end;

procedure TfrmUpdate.btnUpdateClick(Sender: TObject);
var
  strUpdateDatabaseName: string;
begin
  btnUpdate.Enabled := False;
  try
    LogInfo('�������ݿ⿪ʼ');

    { �µ����ݿ⻹ԭ }
    if not RestoreDatabase(edtBakFileName.Text, cbbLibrary.Text, cbbLibrary.Text + '_LOG', strUpdateDatabaseName) then
      Exit;

    try
      CheckTable(strUpdateDatabaseName);   // ����
      CheckView(strUpdateDatabaseName);    // �����ͼ
      CheckProc(strUpdateDatabaseName);    // ���洢����
      CheckTrigger(strUpdateDatabaseName); // ��鴥����
      CheckFunc(strUpdateDatabaseName);    // ����Զ��庯��
    finally
      { ɾ����ʱ���������ݿ� }
      DeleteUpdateDataBase(strUpdateDatabaseName);
    end;
  finally
    LogInfo('�������ݿ����');
    btnUpdate.Enabled := True;
  end;
end;

end.
