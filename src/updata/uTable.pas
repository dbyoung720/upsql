unit uTable;

interface

uses System.Classes, System.SysUtils, System.Variants, Vcl.Forms, Data.DB, Data.Win.ADODB;

{ 创建不存在的表 }
procedure CreateNotExistTable(const strOldDataBaseName, strUpdateDatabaseName: string);

{ 删除不需要的表 }
procedure DeleteNoNeededTable(const strOldDataBaseName, strUpdateDatabaseName: string);

{ 升级已存在的表 }
procedure UpdateYesExistTable(const strOldDataBaseName, strUpdateDatabaseName: string);

implementation

uses Unit1;

{ 比较两表结构是否相同 }
function SameTableStructure(const strOldDataBaseName, strUpdateDatabaseName, strTableName: string): Boolean;
const
  c_strSQL =                                                                                                                                                                                                                                                                                                     //
    ' select * from (  ' +                                                                                                                                                                                                                                                                                       //
    '   select name,xtype,typestat,xusertype,length,xprec,xscale,colid,xoffset,bitpos,colstat,domain,number,colorder,offset,collation,language,status,type,usertype,prec,scale,iscomputed, isoutparam, isnullable from %s.dbo.syscolumns ' + ' where id=(select id from %s.dbo.sysobjects where name=''%s'') ' + //
    ' ) A ' +                                                                                                                                                                                                                                                                                                    //
    ' except ' +                                                                                                                                                                                                                                                                                                 //
    ' select * from  ' +                                                                                                                                                                                                                                                                                         //
    ' (  ' +                                                                                                                                                                                                                                                                                                     //
    '   select name,xtype,typestat,xusertype,length,xprec,xscale,colid,xoffset,bitpos,colstat,domain,number,colorder,offset,collation,language,status,type,usertype,prec,scale,iscomputed, isoutparam, isnullable from %s.dbo.syscolumns ' + ' where id=(select id from %s.dbo.sysobjects where name=''%s'') ' + //
    ' ) B';
begin
  frmUpdate.qry3.Close;
  frmUpdate.qry3.SQL.Clear;
  frmUpdate.qry3.SQL.Text := Format(c_strSQL, [strUpdateDatabaseName, strUpdateDatabaseName, strTableName, strOldDataBaseName, strOldDataBaseName, strTableName]);
  frmUpdate.qry3.Open;
  Result := frmUpdate.qry3.RecordCount = 0;
end;

{ 创建不存在的表 }
procedure CreateNotExistTable(const strOldDataBaseName, strUpdateDatabaseName: string);
var
  strTableName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('use %s select name from sys.tables where type=''U'' ORDER BY name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('use %s select name from sys.tables where type=''U'' ORDER BY name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry2.First;
  while not frmUpdate.qry2.Eof do
  begin
    Application.ProcessMessages;
    strTableName := frmUpdate.qry2.Fields[0].AsString;
    if not frmUpdate.qry1.Locate('name', strTableName, []) then
    begin
      frmUpdate.LogInfo(Format('创建新表：%s', [strTableName]));
      frmUpdate.qry3.Close;
      frmUpdate.qry3.SQL.Clear;
      frmUpdate.qry3.SQL.Text := Format('select * into %s.dbo.%s from %s.dbo.%s where 0=1', [strOldDataBaseName, strTableName, strUpdateDatabaseName, strTableName]);
      try
        frmUpdate.qry3.ExecSQL;
      except
        on E: Exception do
        begin
          frmUpdate.LogInfo(Format('创建新表失败。表名: %s，原因: %s', [strTableName, E.Message]));
          frmUpdate.LogInfo(frmUpdate.qry3.SQL.Text);
        end;
      end;
    end;
    frmUpdate.qry2.Next;
  end;
end;

{ 删除不需要的表 }
procedure DeleteNoNeededTable(const strOldDataBaseName, strUpdateDatabaseName: string);
var
  strTableName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('use %s select name from sys.tables where type=''U'' ORDER BY name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('use %s select name from sys.tables where type=''U'' ORDER BY name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry1.First;
  while not frmUpdate.qry1.Eof do
  begin
    Application.ProcessMessages;
    strTableName := frmUpdate.qry1.Fields[0].AsString;
    if not frmUpdate.qry2.Locate('name', strTableName, []) then
    begin
      frmUpdate.LogInfo(Format('删除表：%s', [strTableName]));
      frmUpdate.qry3.Close;
      frmUpdate.qry3.SQL.Clear;
      frmUpdate.qry3.SQL.Text := Format('drop table %s.dbo.%s', [strOldDataBaseName, strTableName]);
      try
        frmUpdate.qry3.ExecSQL;
      except
        on E: Exception do
        begin
          frmUpdate.LogInfo(Format('删除表失败。表名: %s，原因: %s', [strTableName, E.Message]));
          frmUpdate.LogInfo(frmUpdate.qry3.SQL.Text);
        end;
      end;
    end;
    frmUpdate.qry1.Next;
  end;
end;

function GetDataFields(const strOldDataBaseName, strUpdateDatabaseName, strTableName: string): string;
var
  strFieldName: string;
  lstFields   : TStringList;
begin
  frmUpdate.qry3.Close;
  frmUpdate.qry3.SQL.Clear;
  frmUpdate.qry3.SQL.Text := Format('use %s select name from sys.columns where OBJECT_NAME(object_id) = %s', [strOldDataBaseName, QuotedStr(strTableName)]);
  frmUpdate.qry3.Open;

  frmUpdate.qry4.Close;
  frmUpdate.qry4.SQL.Clear;
  frmUpdate.qry4.SQL.Text := Format('use %s select name from sys.columns where OBJECT_NAME(object_id) = %s', [strUpdateDatabaseName, QuotedStr(strTableName)]);
  frmUpdate.qry4.Open;

  lstFields := TStringList.Create;
  frmUpdate.qry4.First;
  while not frmUpdate.qry4.Eof do
  begin
    strFieldName := frmUpdate.qry4.Fields[0].AsString;
    if frmUpdate.qry3.Locate('name', strFieldName, []) then
    begin
      lstFields.Add(strFieldName);
    end;
    frmUpdate.qry4.Next;
  end;
  Result := lstFields.DelimitedText;
  lstFields.Free;
end;

{ 升级已存在的表 }
procedure UpdateYesExistTable(const strOldDataBaseName, strUpdateDatabaseName: string);
const
  c_strSQL =                                                 //
    ' select * into %s.dbo.%s from %s.dbo.%s where 0=1 ' +   // 1 创建临时新表
    ' set IDENTITY_INSERT %s.dbo.%s ON ' +                   // 2 开启将显式值插入表的标识列中
    ' INSERT INTO %s.dbo.%s(%s) select %s from %s.dbo.%s ' + // 2 将旧表数据插入新的临时表
    ' set IDENTITY_INSERT %s.dbo.%s OFF ' +                  // 2 关闭将显式值插入表的标识列中
    ' DROP TABLE %s.dbo.%s ' +                               // 3 删除旧表
    ' use %s EXEC sp_rename N''%s'', N''%s''';              // 4 将临时新表重命名为旧表名
var
  strTableName    : string;
  strTempTableName: string;
  strFields       : string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('use %s select name from sys.tables where type=''U'' ORDER BY name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('use %s select name from sys.tables where type=''U'' ORDER BY name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry2.First;
  while not frmUpdate.qry2.Eof do
  begin
    Application.ProcessMessages;
    strTableName := frmUpdate.qry2.Fields[0].AsString;
    if frmUpdate.qry1.Locate('name', strTableName, []) then
    begin
      { 比较两表结构是否相同 }
      if not SameTableStructure(strOldDataBaseName, strUpdateDatabaseName, strTableName) then
      begin
        frmUpdate.LogInfo(Format('升级表：%s', [strTableName]));
        strTempTableName := 'db_temp_' + strTableName;
        strFields        := GetDataFields(strOldDataBaseName, strUpdateDatabaseName, strTableName);
        frmUpdate.qry4.Close;
        frmUpdate.qry4.SQL.Clear;
        frmUpdate.qry4.SQL.Text := Format(c_strSQL, [                                                   //
          strOldDataBaseName, strTempTableName, strUpdateDatabaseName, strTableName,                    // 1 创建临时新表
          strOldDataBaseName, strTempTableName,                                                         // 2 开启将显式值插入表的标识列中
          strOldDataBaseName, strTempTableName, strFields, strFields, strOldDataBaseName, strTableName, // 2 将旧表数据插入新的临时表
          strOldDataBaseName, strTempTableName,                                                         // 2 关闭将显式值插入表的标识列中
          strOldDataBaseName, strTableName,                                                             // 3 删除旧表
          strOldDataBaseName, strTempTableName, strTableName                                            // 4 将临时新表重命名为旧表名
          ]);
        try
          frmUpdate.qry4.ExecSQL;
        except
          on E: Exception do
          begin
            frmUpdate.LogInfo(Format('升级表失败。表名: %s，原因: %s', [strTableName, E.Message]));
            frmUpdate.LogInfo(frmUpdate.qry4.SQL.Text);
          end;
        end;
      end;
    end;
    frmUpdate.qry2.Next;
  end;
end;

end.
