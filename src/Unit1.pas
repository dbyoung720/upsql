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
    { 列举所有库 }
    procedure GetDatabaseLibraryList;
    { 获取当前目录下是否有数据库备份文件 }
    procedure GetDatabaseBackupFile;
    { 新的数据库还原 }
    function RestoreDatabase(const strBakFileName, strDBDataName, strDBLogName: string; var strUpdateDatabaseName: string): Boolean;
    { 删除临时的升级数据库 }
    procedure DeleteUpdateDataBase(const strDatabaseName: string);
    { 检查表 }
    procedure CheckTable(const strUpdateDatabaseName: string);
    { 检查视图 }
    procedure CheckView(const strUpdateDatabaseName: string);
    { 检查触发器 }
    procedure CheckTrigger(const strUpdateDatabaseName: string);
    { 检查存储过程 }
    procedure CheckProc(const strUpdateDatabaseName: string);
    { 检查自定义函数 }
    procedure CheckFunc(const strUpdateDatabaseName: string);
  public
    { 日志 }
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
    Caption := '数据库升级---没有找到 udl 数据库连接文件';
    Exit;
  end;

  strFileName           := mfiles[0];
  con1.KeepConnection   := True;
  con1.LoginPrompt      := False;
  con1.Provider         := strFileName;
  con1.ConnectionString := 'FILE NAME=' + strFileName;
  try
    con1.Connected := True;
    Caption        := '数据库升级---数据库连接成功';
    GetDatabaseLibraryList;
    GetDatabaseBackupFile;
  except
    Caption := '数据库升级---数据库连接失败';
  end;
end;

{ 列举所有库 }
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

{ 获取当前目录下是否有数据库备份文件 }
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

{ 删除临时的升级数据库 }
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
      LogInfo('删除升级数据库失败。原因：' + E.Message);
      LogInfo(qry1.SQL.Text);
    end;
  end;
end;

{ 新的数据库还原 }
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
    [strUpdateDatabaseName,                                  // 数据库名称
    QuotedStr(strBakFileName),                               // 新的数据库备份文件
    QuotedStr(strDBDataName),                                // 原有的数据文件逻辑名称
    QuotedStr(strDBPath + strUpdateDatabaseName + '.mdf'),   // 指定数据文件路径
    QuotedStr(strDBLogName),                                 // 原有的日志文件逻辑名称
    QuotedStr(strDBPath + strUpdateDatabaseName + '.ldf')]); // 指定日志文件路径
  try
    qry1.ExecSQL;
  except
    on E: Exception do
    begin
      Result := False;
      LogInfo('还原数据库失败。原因：' + E.Message);
      LogInfo(qry1.SQL.Text);
    end;
  end;
end;

{ 检查表 }
procedure TfrmUpdate.CheckTable(const strUpdateDatabaseName: string);
begin
  CreateNotExistTable(cbbLibrary.Text, strUpdateDatabaseName); // 创建不存在的表
  DeleteNoNeededTable(cbbLibrary.Text, strUpdateDatabaseName); // 删除不需要的表
  UpdateYesExistTable(cbbLibrary.Text, strUpdateDatabaseName); // 升级已存在的表
end;

{ 检查视图 }
procedure TfrmUpdate.CheckView(const strUpdateDatabaseName: string);
begin
  CreateNotExistView(cbbLibrary.Text, strUpdateDatabaseName); // 创建不存在的视图
  DeleteNoNeededView(cbbLibrary.Text, strUpdateDatabaseName); // 删除不需要的视图
  UpdateYesExistView(cbbLibrary.Text, strUpdateDatabaseName); // 升级已存在的视图
end;

{ 检查触发器 }
procedure TfrmUpdate.CheckTrigger(const strUpdateDatabaseName: string);
begin
  CreateNotExistTrigger(cbbLibrary.Text, strUpdateDatabaseName); // 创建不存在的触发器
  DeleteNoNeededTrigger(cbbLibrary.Text, strUpdateDatabaseName); // 删除不需要的触发器
  UpdateYesExistTrigger(cbbLibrary.Text, strUpdateDatabaseName); // 升级已存在的触发器
end;

{ 检查存储过程 }
procedure TfrmUpdate.CheckProc(const strUpdateDatabaseName: string);
begin
  CreateNotExistProc(cbbLibrary.Text, strUpdateDatabaseName); // 创建不存在的存储过程
  DeleteNoNeededProc(cbbLibrary.Text, strUpdateDatabaseName); // 删除不需要的存储过程
  UpdateYesExistProc(cbbLibrary.Text, strUpdateDatabaseName); // 升级已存在的存储过程
end;

{ 检查自定义函数 }
procedure TfrmUpdate.CheckFunc(const strUpdateDatabaseName: string);
begin
  CreateNotExistFunc(cbbLibrary.Text, strUpdateDatabaseName); // 创建不存在的自定义函数
  DeleteNoNeededFunc(cbbLibrary.Text, strUpdateDatabaseName); // 删除不需要的自定义函数
  UpdateYesExistFunc(cbbLibrary.Text, strUpdateDatabaseName); // 升级已存在的自定义函数
end;

procedure TfrmUpdate.btnUpdateClick(Sender: TObject);
var
  strUpdateDatabaseName: string;
begin
  btnUpdate.Enabled := False;
  try
    LogInfo('升级数据库开始');

    { 新的数据库还原 }
    if not RestoreDatabase(edtBakFileName.Text, cbbLibrary.Text, cbbLibrary.Text + '_LOG', strUpdateDatabaseName) then
      Exit;

    try
      CheckTable(strUpdateDatabaseName);   // 检查表
      CheckView(strUpdateDatabaseName);    // 检查视图
      CheckProc(strUpdateDatabaseName);    // 检查存储过程
      CheckTrigger(strUpdateDatabaseName); // 检查触发器
      CheckFunc(strUpdateDatabaseName);    // 检查自定义函数
    finally
      { 删除临时的升级数据库 }
      DeleteUpdateDataBase(strUpdateDatabaseName);
    end;
  finally
    LogInfo('升级数据库完成');
    btnUpdate.Enabled := True;
  end;
end;

end.
