unit uTrigger;

interface

uses System.SysUtils, System.Variants, Vcl.Forms, Data.DB, Data.Win.ADODB;

{ 创建不存在的触发器 }
procedure CreateNotExistTrigger(const strOldDataBaseName, strUpdateDatabaseName: string);

{ 删除不需要的触发器 }
procedure DeleteNoNeededTrigger(const strOldDataBaseName, strUpdateDatabaseName: string);

{ 升级已存在的触发器 }
procedure UpdateYesExistTrigger(const strOldDataBaseName, strUpdateDatabaseName: string);

implementation

uses Unit1;

{ 创建不存在的触发器 }
procedure CreateNotExistTrigger(const strOldDataBaseName, strUpdateDatabaseName: string);
const
  c_strSQL = 'use %s SELECT text FROM sys.syscomments WHERE OBJECTPROPERTY(id, ''IsTrigger'') = 1 and OBJECT_NAME(id)=%s';
var
  strTriggerName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('select name from %s.sys.triggers order by name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('select name from %s.sys.triggers order by name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  if frmUpdate.qry2.RecordCount <= 0 then
    Exit;

  frmUpdate.qry2.First;
  while not frmUpdate.qry2.Eof do
  begin
    strTriggerName := frmUpdate.qry2.Fields[0].AsString;
    if not frmUpdate.qry1.Locate('name', strTriggerName, []) then
    begin
      frmUpdate.qry3.Close;
      frmUpdate.qry3.SQL.Clear;
      frmUpdate.qry3.SQL.Text := Format(c_strSQL, [strUpdateDatabaseName, QuotedStr(strTriggerName)]);
      frmUpdate.qry3.Open;
      if frmUpdate.qry3.RecordCount > 0 then
      begin
        frmUpdate.LogInfo(Format('创建触发器：%s', [strTriggerName]));
        frmUpdate.qry4.Close;
        frmUpdate.qry4.SQL.Clear;
        frmUpdate.qry4.SQL.Text := Format('use %s %s', [strOldDataBaseName, frmUpdate.qry3.Fields[0].AsString]);
        try
          frmUpdate.qry4.ExecSQL;
        except
          on E: Exception do
          begin
            frmUpdate.LogInfo(Format('创建触发器失败。触发器名称: %s，原因: %s', [strTriggerName, E.Message]));
            frmUpdate.LogInfo(frmUpdate.qry4.SQL.Text);
          end;
        end;
      end;
    end;
    frmUpdate.qry2.Next;
  end;
end;

{ 删除不需要的触发器 }
procedure DeleteNoNeededTrigger(const strOldDataBaseName, strUpdateDatabaseName: string);
var
  strTriggerName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('select name from %s.sys.triggers order by name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('select name from %s.sys.triggers order by name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry1.First;
  while not frmUpdate.qry1.Eof do
  begin
    Application.ProcessMessages;
    strTriggerName := frmUpdate.qry1.Fields[0].AsString;
    if not frmUpdate.qry2.Locate('name', strTriggerName, []) then
    begin
      frmUpdate.LogInfo(Format('删除触发器：%s', [strTriggerName]));
      frmUpdate.qry3.Close;
      frmUpdate.qry3.SQL.Clear;
      frmUpdate.qry3.SQL.Text := Format('drop trigger %s.dbo.%s', [strOldDataBaseName, strTriggerName]);
      try
        frmUpdate.qry3.ExecSQL;
      except
        on E: Exception do
        begin
          frmUpdate.LogInfo(Format('删除触发器失败。触发器名称: %s，原因: %s', [strTriggerName, E.Message]));
          frmUpdate.LogInfo(frmUpdate.qry3.SQL.Text);
        end;
      end;
    end;
    frmUpdate.qry1.Next;
  end;
end;

{ 比较两触发器是否相同 }
function SameTrigger(const strOldDataBaseName, strUpdateDatabaseName, strTriggerName: string): Boolean;
var
  strOldTriggerCode: string;
  strNewTriggerCode: string;
  I                : Integer;
begin
  frmUpdate.qry3.Close;
  frmUpdate.qry3.SQL.Clear;
  frmUpdate.qry3.SQL.Text := Format('exec %s.dbo.sp_helptext %s', [strOldDataBaseName, QuotedStr(strTriggerName)]);
  frmUpdate.qry3.Open;

  frmUpdate.qry4.Close;
  frmUpdate.qry4.SQL.Clear;
  frmUpdate.qry4.SQL.Text := Format('exec %s.dbo.sp_helptext %s', [strUpdateDatabaseName, QuotedStr(strTriggerName)]);
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
    strOldTriggerCode := Trim(frmUpdate.qry3.Fields[0].AsString);
    strNewTriggerCode := Trim(frmUpdate.qry4.Fields[0].AsString);
    if not SameText(strOldTriggerCode, strNewTriggerCode) then
    begin
      Result := False;
      Break;
    end;
    frmUpdate.qry3.Next;
    frmUpdate.qry4.Next;
  end;
end;

{ 升级已存在的触发器 }
procedure UpdateYesExistTrigger(const strOldDataBaseName, strUpdateDatabaseName: string);
var
  strTriggerName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('select name from %s.sys.triggers order by name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('select name from %s.sys.triggers order by name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry2.First;
  while not frmUpdate.qry2.Eof do
  begin
    Application.ProcessMessages;
    strTriggerName := frmUpdate.qry2.Fields[0].AsString;
    if frmUpdate.qry1.Locate('name', strTriggerName, []) then
    begin
      { 比较两存储过程是否相同 }
      if not SameTrigger(strOldDataBaseName, strUpdateDatabaseName, strTriggerName) then
      begin
        frmUpdate.LogInfo(Format('升级触发器：%s', [strTriggerName]));
        frmUpdate.qry3.Close;
        frmUpdate.qry3.SQL.Clear;
        frmUpdate.qry3.SQL.Text := Format('drop trigger %s.dbo.%s', [strOldDataBaseName, strTriggerName]);
        try
          frmUpdate.qry3.ExecSQL;
        except
          on E: Exception do
          begin
            frmUpdate.LogInfo(Format('升级触发器失败1。触发器名称: %s，原因: %s', [strTriggerName, E.Message]));
            frmUpdate.LogInfo(frmUpdate.qry3.SQL.Text);
          end;
        end;

        frmUpdate.qry3.Close;
        frmUpdate.qry3.SQL.Clear;
        frmUpdate.qry3.SQL.Text := Format('use %s SELECT text FROM sys.syscomments WHERE OBJECTPROPERTY(id, ''IsTrigger'') = 1 and OBJECT_NAME(id)=%s', [strUpdateDatabaseName, QuotedStr(strTriggerName)]);
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
              frmUpdate.LogInfo(Format('升级触发器失败2。触发器名称: %s，原因: %s', [strTriggerName, E.Message]));
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
