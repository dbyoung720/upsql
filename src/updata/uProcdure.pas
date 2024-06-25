unit uProcdure;

interface

uses System.SysUtils, System.Variants, Vcl.Forms, Data.DB, Data.Win.ADODB;

{ 创建不存在的存储过程 }
procedure CreateNotExistProc(const strOldDataBaseName, strUpdateDatabaseName: string);

{ 删除不需要的存储过程 }
procedure DeleteNoNeededProc(const strOldDataBaseName, strUpdateDatabaseName: string);

{ 升级已存在的存储过程 }
procedure UpdateYesExistProc(const strOldDataBaseName, strUpdateDatabaseName: string);

implementation

uses Unit1;

{ 创建不存在的存储过程 }
procedure CreateNotExistProc(const strOldDataBaseName, strUpdateDatabaseName: string);
const
  c_strSQL = 'use %s SELECT text FROM sys.syscomments WHERE OBJECTPROPERTY(id, ''IsProcedure'') = 1 and OBJECT_NAME(id)=%s';
var
  strProcName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('select name from %s.sys.procedures order by name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('select name from %s.sys.procedures order by name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  if frmUpdate.qry2.RecordCount <= 0 then
    Exit;

  frmUpdate.qry2.First;
  while not frmUpdate.qry2.Eof do
  begin
    strProcName := frmUpdate.qry2.Fields[0].AsString;
    if not frmUpdate.qry1.Locate('name', strProcName, []) then
    begin
      frmUpdate.qry3.Close;
      frmUpdate.qry3.SQL.Clear;
      frmUpdate.qry3.SQL.Text := Format(c_strSQL, [strUpdateDatabaseName, QuotedStr(strProcName)]);
      frmUpdate.qry3.Open;
      if frmUpdate.qry3.RecordCount > 0 then
      begin
        frmUpdate.LogInfo(Format('创建存储过程：%s', [strProcName]));
        frmUpdate.qry4.Close;
        frmUpdate.qry4.SQL.Clear;
        frmUpdate.qry4.SQL.Text := Format('use %s %s', [strOldDataBaseName, frmUpdate.qry3.Fields[0].AsString]);
        try
          frmUpdate.qry4.ExecSQL;
        except
          on E: Exception do
          begin
            frmUpdate.LogInfo(Format('创建存储过程失败。存储过程名称: %s，原因: %s', [strProcName, E.Message]));
            frmUpdate.LogInfo(frmUpdate.qry4.SQL.Text);
          end;
        end;
      end;
    end;
    frmUpdate.qry2.Next;
  end;
end;

{ 删除不需要的存储过程 }
procedure DeleteNoNeededProc(const strOldDataBaseName, strUpdateDatabaseName: string);
var
  strProcName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('select name from %s.sys.procedures order by name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('select name from %s.sys.procedures order by name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry1.First;
  while not frmUpdate.qry1.Eof do
  begin
    Application.ProcessMessages;
    strProcName := frmUpdate.qry1.Fields[0].AsString;
    if not frmUpdate.qry2.Locate('name', strProcName, []) then
    begin
      frmUpdate.LogInfo(Format('删除存储过程：%s', [strProcName]));
      frmUpdate.qry3.Close;
      frmUpdate.qry3.SQL.Clear;
      frmUpdate.qry3.SQL.Text := Format('drop procedure %s.dbo.%s', [strOldDataBaseName, strProcName]);
      try
        frmUpdate.qry3.ExecSQL;
      except
        on E: Exception do
        begin
          frmUpdate.LogInfo(Format('删除存储过程失败。存储过程名称: %s，原因: %s', [strProcName, E.Message]));
          frmUpdate.LogInfo(frmUpdate.qry3.SQL.Text);
        end;
      end;
    end;
    frmUpdate.qry1.Next;
  end;
end;

{ 比较两存储过程是否相同 }
function SameProc(const strOldDataBaseName, strUpdateDatabaseName, strProcName: string): Boolean;
var
  strOldProcCode: string;
  strNewProcCode: string;
  I             : Integer;
begin
  frmUpdate.qry3.Close;
  frmUpdate.qry3.SQL.Clear;
  frmUpdate.qry3.SQL.Text := Format('exec %s.dbo.sp_helptext %s', [strOldDataBaseName, QuotedStr(strProcName)]);
  frmUpdate.qry3.Open;

  frmUpdate.qry4.Close;
  frmUpdate.qry4.SQL.Clear;
  frmUpdate.qry4.SQL.Text := Format('exec %s.dbo.sp_helptext %s', [strUpdateDatabaseName, QuotedStr(strProcName)]);
  frmUpdate.qry4.Open;

  if frmUpdate.qry4.RecordCount <> frmUpdate.qry3.RecordCount then
  begin
    Result := False;
    Exit;
  end;

  Result := True;
  frmUpdate.qry3.First;
  frmUpdate.qry4.First;
  for I := 0 to frmUpdate.qry4.RecordCount - 1 do
  begin
    strOldProcCode := Trim(frmUpdate.qry3.Fields[0].AsString);
    strNewProcCode := Trim(frmUpdate.qry4.Fields[0].AsString);
    if not SameText(strOldProcCode, strNewProcCode) then
    begin
      Result := False;
      Break;
    end;
    frmUpdate.qry3.Next;
    frmUpdate.qry4.Next;
  end;
end;

{ 升级已存在的存储过程 }
procedure UpdateYesExistProc(const strOldDataBaseName, strUpdateDatabaseName: string);
var
  strProcName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('select name from %s.sys.procedures order by name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('select name from %s.sys.procedures order by name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry2.First;
  while not frmUpdate.qry2.Eof do
  begin
    Application.ProcessMessages;
    strProcName := frmUpdate.qry2.Fields[0].AsString;
    if frmUpdate.qry1.Locate('name', strProcName, []) then
    begin
      { 比较两存储过程是否相同 }
      if not SameProc(strOldDataBaseName, strUpdateDatabaseName, strProcName) then
      begin
        frmUpdate.LogInfo(Format('升级存储过程：%s', [strProcName]));
        frmUpdate.qry3.Close;
        frmUpdate.qry3.SQL.Clear;
        frmUpdate.qry3.SQL.Text := Format('drop procedure %s.dbo.%s', [strOldDataBaseName, strProcName]);
        try
          frmUpdate.qry3.ExecSQL;
        except
          on E: Exception do
          begin
            frmUpdate.LogInfo(Format('升级存储过程失败1。存储过程名称: %s，原因: %s', [strProcName, E.Message]));
            frmUpdate.LogInfo(frmUpdate.qry3.SQL.Text);
          end;
        end;

        frmUpdate.qry3.Close;
        frmUpdate.qry3.SQL.Clear;
        frmUpdate.qry3.SQL.Text := Format('use %s SELECT text FROM sys.syscomments WHERE OBJECTPROPERTY(id, ''IsProcedure'') = 1 and OBJECT_NAME(id)=%s', [strUpdateDatabaseName, QuotedStr(strProcName)]);
        frmUpdate.qry3.Open;
        if frmUpdate.qry3.RecordCount > 0 then
        begin
          frmUpdate.qry4.Close;
          frmUpdate.qry4.SQL.Clear;
          frmUpdate.qry4.SQL.Text := Format('use %s %s', [strOldDataBaseName, frmUpdate.qry3.Fields[0].AsString]);
          try
            frmUpdate.qry4.ExecSQL;
          except
            on E: Exception do
            begin
              frmUpdate.LogInfo(Format('升级存储过程失败2。存储过程名称: %s，原因: %s', [strProcName, E.Message]));
              frmUpdate.LogInfo(frmUpdate.qry4.SQL.Text);
            end;
          end;
        end;

      end;
    end;
    frmUpdate.qry2.Next;
  end;
end;

end.
