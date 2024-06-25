unit uFunction;

interface

uses System.SysUtils, System.Variants, Vcl.Forms, Data.DB, Data.Win.ADODB;

{ ���������ڵ��Զ��庯�� }
procedure CreateNotExistFunc(const strOldDataBaseName, strUpdateDatabaseName: string);

{ ɾ������Ҫ���Զ��庯�� }
procedure DeleteNoNeededFunc(const strOldDataBaseName, strUpdateDatabaseName: string);

{ �����Ѵ��ڵ��Զ��庯�� }
procedure UpdateYesExistFunc(const strOldDataBaseName, strUpdateDatabaseName: string);

implementation

uses Unit1;

{ ���������ڵ��Զ��庯�� }
procedure CreateNotExistFunc(const strOldDataBaseName, strUpdateDatabaseName: string);
const
  c_strSQL = 'use %s SELECT text FROM sys.syscomments where (OBJECTPROPERTY(id, ''IsScalarFunction'') = 1) or (OBJECTPROPERTY(id, ''IsTableFunction'') = 1) and OBJECT_NAME(id)=%s';
var
  strFuncName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('use %s SELECT OBJECT_NAME(id) name FROM sys.syscomments WHERE (OBJECTPROPERTY(id, ''IsScalarFunction'') = 1) or (OBJECTPROPERTY(id, ''IsTableFunction'') = 1) order by name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('use %s SELECT OBJECT_NAME(id) name FROM sys.syscomments WHERE (OBJECTPROPERTY(id, ''IsScalarFunction'') = 1) or (OBJECTPROPERTY(id, ''IsTableFunction'') = 1) order by name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  if frmUpdate.qry2.RecordCount <= 0 then
    Exit;

  frmUpdate.qry2.First;
  while not frmUpdate.qry2.Eof do
  begin
    strFuncName := frmUpdate.qry2.Fields[0].AsString;
    if not frmUpdate.qry1.Locate('name', strFuncName, []) then
    begin
      frmUpdate.qry3.Close;
      frmUpdate.qry3.SQL.Clear;
      frmUpdate.qry3.SQL.Add(Format('use %s', [strOldDataBaseName]));
      frmUpdate.qry3.SQL.Add(Format(c_strSQL, [strUpdateDatabaseName, QuotedStr(strFuncName)]));
      frmUpdate.qry3.Open;
      if frmUpdate.qry3.RecordCount > 0 then
      begin
        frmUpdate.LogInfo(Format('�����Զ��庯����%s', [strFuncName]));
        frmUpdate.qry4.Close;
        frmUpdate.qry4.SQL.Clear;
        frmUpdate.qry4.SQL.Text := Format('use %s %s', [strOldDataBaseName, frmUpdate.qry3.Fields[0].AsString]);
        try
          frmUpdate.qry4.ExecSQL;
        except
          on E: Exception do
          begin
            frmUpdate.LogInfo(Format('�����Զ��庯��ʧ�ܡ�����������: %s��ԭ��: %s', [strFuncName, E.Message]));
            frmUpdate.LogInfo(frmUpdate.qry4.SQL.Text);
          end;
        end;
      end;
    end;
    frmUpdate.qry2.Next;
  end;
end;

{ ɾ������Ҫ���Զ��庯�� }
procedure DeleteNoNeededFunc(const strOldDataBaseName, strUpdateDatabaseName: string);
var
  strFuncName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('use %s SELECT OBJECT_NAME(id) name FROM sys.syscomments WHERE (OBJECTPROPERTY(id, ''IsScalarFunction'') = 1) or (OBJECTPROPERTY(id, ''IsTableFunction'') = 1) order by name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('use %s SELECT OBJECT_NAME(id) name FROM sys.syscomments WHERE (OBJECTPROPERTY(id, ''IsScalarFunction'') = 1) or (OBJECTPROPERTY(id, ''IsTableFunction'') = 1) order by name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry1.First;
  while not frmUpdate.qry1.Eof do
  begin
    Application.ProcessMessages;
    strFuncName := frmUpdate.qry1.Fields[0].AsString;
    if not frmUpdate.qry2.Locate('name', strFuncName, []) then
    begin
      frmUpdate.LogInfo(Format('ɾ����������%s', [strFuncName]));
      frmUpdate.qry3.Close;
      frmUpdate.qry3.SQL.Clear;
      frmUpdate.qry3.SQL.Text := Format('drop function %s.dbo.%s', [strOldDataBaseName, strFuncName]);
      try
        frmUpdate.qry3.ExecSQL;
      except
        on E: Exception do
        begin
          frmUpdate.LogInfo(Format('ɾ��������ʧ�ܡ�����������: %s��ԭ��: %s', [strFuncName, E.Message]));
          frmUpdate.LogInfo(frmUpdate.qry3.SQL.Text);
        end;
      end;
    end;
    frmUpdate.qry1.Next;
  end;
end;

{ �Ƚ����Զ��庯���Ƿ���ͬ }
function SameFunc(const strOldDataBaseName, strUpdateDatabaseName, strFuncName: string): Boolean;
var
  strOldFuncCode: string;
  strNewFuncCode: string;
  I             : Integer;
begin
  frmUpdate.qry3.Close;
  frmUpdate.qry3.SQL.Clear;
  frmUpdate.qry3.SQL.Text := Format('exec %s.dbo.sp_helptext %s', [strOldDataBaseName, QuotedStr(strFuncName)]);
  frmUpdate.qry3.Open;

  frmUpdate.qry4.Close;
  frmUpdate.qry4.SQL.Clear;
  frmUpdate.qry4.SQL.Text := Format('exec %s.dbo.sp_helptext %s', [strUpdateDatabaseName, QuotedStr(strFuncName)]);
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
    strOldFuncCode := Trim(frmUpdate.qry3.Fields[0].AsString);
    strNewFuncCode := Trim(frmUpdate.qry4.Fields[0].AsString);
    if not SameText(strOldFuncCode, strNewFuncCode) then
    begin
      Result := False;
      Break;
    end;
    frmUpdate.qry3.Next;
    frmUpdate.qry4.Next;
  end;
end;

{ �����Ѵ��ڵ��Զ��庯�� }
procedure UpdateYesExistFunc(const strOldDataBaseName, strUpdateDatabaseName: string);
var
  strFuncName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('use %s SELECT OBJECT_NAME(id) name FROM sys.syscomments WHERE (OBJECTPROPERTY(id, ''IsScalarFunction'') = 1) or (OBJECTPROPERTY(id, ''IsTableFunction'') = 1) order by name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('use %s SELECT OBJECT_NAME(id) name FROM sys.syscomments WHERE (OBJECTPROPERTY(id, ''IsScalarFunction'') = 1) or (OBJECTPROPERTY(id, ''IsTableFunction'') = 1) order by name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry2.First;
  while not frmUpdate.qry2.Eof do
  begin
    Application.ProcessMessages;
    strFuncName := frmUpdate.qry2.Fields[0].AsString;
    if frmUpdate.qry1.Locate('name', strFuncName, []) then
    begin
      { �Ƚ����洢�����Ƿ���ͬ }
      if not SameFunc(strOldDataBaseName, strUpdateDatabaseName, strFuncName) then
      begin
        frmUpdate.LogInfo(Format('�����Զ��庯����%s', [strFuncName]));
        frmUpdate.qry3.Close;
        frmUpdate.qry3.SQL.Clear;
        frmUpdate.qry3.SQL.Text := Format('drop function %s.dbo.%s', [strOldDataBaseName, strFuncName]);
        try
          frmUpdate.qry3.ExecSQL;
        except
          on E: Exception do
          begin
            frmUpdate.LogInfo(Format('�����Զ��庯��ʧ��1���Զ��庯������: %s��ԭ��: %s', [strFuncName, E.Message]));
            frmUpdate.LogInfo(frmUpdate.qry3.SQL.Text);
          end;
        end;

        frmUpdate.qry3.Close;
        frmUpdate.qry3.SQL.Clear;
        frmUpdate.qry3.SQL.Text := Format('use %s SELECT text FROM sys.syscomments WHERE ((OBJECTPROPERTY(id, ''IsScalarFunction'') = 1) or (OBJECTPROPERTY(id, ''IsTableFunction'') = 1)) and OBJECT_NAME(id)=%s', [strUpdateDatabaseName, QuotedStr(strFuncName)]);
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
              frmUpdate.LogInfo(Format('�����Զ��庯��ʧ��2���Զ��庯������: %s��ԭ��: %s', [strFuncName, E.Message]));
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
