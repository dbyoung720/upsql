unit uView;

interface

uses System.Classes, System.SysUtils, System.Variants, Vcl.Forms, Data.DB, Data.Win.ADODB;

{ ���������ڵ���ͼ }
procedure CreateNotExistView(const strOldDataBaseName, strUpdateDatabaseName: string);

{ ɾ������Ҫ����ͼ }
procedure DeleteNoNeededView(const strOldDataBaseName, strUpdateDatabaseName: string);

{ �����Ѵ��ڵ���ͼ }
procedure UpdateYesExistView(const strOldDataBaseName, strUpdateDatabaseName: string);

implementation

uses Unit1;

{ �Ƚ�����ͼ�ṹ�Ƿ���ͬ }
function SameViewStructure(const strOldDataBaseName, strUpdateDatabaseName, strViewName: string): Boolean;
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
  frmUpdate.qry3.SQL.Text := Format(c_strSQL, [strUpdateDatabaseName, strUpdateDatabaseName, strViewName, strOldDataBaseName, strOldDataBaseName, strViewName]);
  frmUpdate.qry3.Open;
  Result := frmUpdate.qry3.RecordCount = 0;
end;

{ �±�������������� }
function GetCreateKeyIndexSql(const strOldDataBaseName, strUpdateDatabaseName, strOldTableName, strUpdateTableName: string): string;
const
  c_strSQL =                                                                                      //
    ' use %s ' +                                                                                  //
    ' SELECT ' +                                                                                  //
    '     t.name AS TableName, ' +                                                                //
    '     i.name AS IndexName, ' +                                                                //
    '     i.type_desc,' +                                                                         //
    '     i.is_primary_key,' +                                                                    //
    '     c.name AS ColumnName ' +                                                                //
    ' FROM     ' +                                                                                //
    '     sys.indexes AS i ' +                                                                    //
    ' INNER JOIN ' +                                                                              //
    '     sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id  ' + //
    ' INNER JOIN ' +                                                                              //
    '     sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id ' +       //
    ' INNER JOIN      ' +                                                                         //
    '     sys.tables AS t ON i.object_id = t.object_id ' +                                        //
    ' WHERE     ' +                                                                               //
    '     t.is_ms_shipped = 0 and t.name = %s ' +                                                 //
    ' ORDER BY         ' +                                                                        //
    '     t.name, i.name, ic.key_ordinal';
var
  strlist: TStringList;
begin
  Result := '';
  frmUpdate.qry4.Close;
  frmUpdate.qry4.SQL.Clear;
  frmUpdate.qry4.SQL.Text := Format(c_strSQL, [strUpdateDatabaseName, QuotedStr(strUpdateTableName)]);
  frmUpdate.qry4.Open;
  if frmUpdate.qry4.RecordCount <= 0 then
    Exit;

  strlist := TStringList.Create;
  try
    strlist.Add(Format(' USE %s ', [strOldDataBaseName]));
    strlist.Add(Format(' ALTER TABLE %s ', [strOldTableName]));

    frmUpdate.qry4.First;
    while not frmUpdate.qry4.Eof do
    begin
      if frmUpdate.qry4.FieldByName('is_primary_key').AsBoolean then
      begin
        strlist.Add(Format(' ADD CONSTRAINT %s PRIMARY KEY (%s) ', [frmUpdate.qry4.FieldByName('IndexName').AsString, frmUpdate.qry4.FieldByName('ColumnName').AsString]));
      end
      else
      begin
        strlist.Add(Format(' CREATE INDEX %s ON %s(%s) ', [frmUpdate.qry4.FieldByName('IndexName').AsString, strOldTableName, frmUpdate.qry4.FieldByName('ColumnName').AsString]));
      end;
      frmUpdate.qry4.Next;
    end;
    Result := strlist.Text;
  finally
    strlist.Free;
  end;
end;

{ ���������ڵ���ͼ }
procedure CreateNotExistView(const strOldDataBaseName, strUpdateDatabaseName: string);
var
  strViewName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('use %s select name from sys.views where type=''U'' ORDER BY name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('use %s select name from sys.views where type=''U'' ORDER BY name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry2.First;
  while not frmUpdate.qry2.Eof do
  begin
    Application.ProcessMessages;
    strViewName := frmUpdate.qry2.Fields[0].AsString;
    if not frmUpdate.qry1.Locate('name', strViewName, []) then
    begin
      frmUpdate.LogInfo(Format('��������ͼ��%s', [strViewName]));
      frmUpdate.qry3.Close;
      frmUpdate.qry3.SQL.Clear;
      frmUpdate.qry3.SQL.Add(Format('select * into %s.dbo.%s from %s.dbo.%s where 0=1', [strOldDataBaseName, strViewName, strUpdateDatabaseName, strViewName]));
      frmUpdate.qry3.SQL.Add(GetCreateKeyIndexSql(strOldDataBaseName, strUpdateDatabaseName, strViewName, strViewName));
      try
        frmUpdate.qry3.ExecSQL;
      except
        on E: Exception do
        begin
          frmUpdate.LogInfo(Format('��������ͼʧ�ܡ���ͼ��: %s��ԭ��: %s', [strViewName, E.Message]));
          frmUpdate.LogInfo(frmUpdate.qry3.SQL.Text);
        end;
      end;
    end;
    frmUpdate.qry2.Next;
  end;
end;

{ ɾ������Ҫ����ͼ }
procedure DeleteNoNeededView(const strOldDataBaseName, strUpdateDatabaseName: string);
var
  strViewName: string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('use %s select name from sys.views where type=''U'' ORDER BY name;', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('use %s select name from sys.views where type=''U'' ORDER BY name;', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry1.First;
  while not frmUpdate.qry1.Eof do
  begin
    Application.ProcessMessages;
    strViewName := frmUpdate.qry1.Fields[0].AsString;
    if not frmUpdate.qry2.Locate('name', strViewName, []) then
    begin
      frmUpdate.LogInfo(Format('ɾ����ͼ��%s', [strViewName]));
      frmUpdate.qry3.Close;
      frmUpdate.qry3.SQL.Clear;
      frmUpdate.qry3.SQL.Text := Format('drop view %s.dbo.%s', [strOldDataBaseName, strViewName]);
      try
        frmUpdate.qry3.ExecSQL;
      except
        on E: Exception do
        begin
          frmUpdate.LogInfo(Format('ɾ����ͼʧ�ܡ���ͼ��: %s��ԭ��: %s', [strViewName, E.Message]));
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

{ �����Ѵ��ڵ���ͼ }
procedure UpdateYesExistView(const strOldDataBaseName, strUpdateDatabaseName: string);
const
  c_strSQL =                                                 //
    ' select * into %s.dbo.%s from %s.dbo.%s where 0=1 ' +   // 1 ������ʱ����ͼ
    ' %s ' +                                                 // 1 ��ʱ����ͼ�������������
    ' set IDENTITY_INSERT %s.dbo.%s ON ' +                   // 2 ��������ʽֵ������ͼ�ı�ʶ����
    ' INSERT INTO %s.dbo.%s(%s) select %s from %s.dbo.%s ' + // 2 ������ͼ���ݲ����µ���ʱ��ͼ
    ' set IDENTITY_INSERT %s.dbo.%s OFF ' +                  // 2 �رս���ʽֵ������ͼ�ı�ʶ����
    ' DROP TABLE %s.dbo.%s ' +                               // 3 ɾ������ͼ
    ' use %s EXEC sp_rename N''%s'', N''%s''';               // 4 ����ʱ����ͼ������Ϊ����ͼ��
var
  strViewName     : string;
  strTempTableName: string;
  strFields       : string;
begin
  frmUpdate.qry1.Close;
  frmUpdate.qry1.SQL.Clear;
  frmUpdate.qry1.SQL.Text := Format('use %s select name from sys.views where type=''U'' ORDER BY name', [strOldDataBaseName]);
  frmUpdate.qry1.Open;

  frmUpdate.qry2.Close;
  frmUpdate.qry2.SQL.Clear;
  frmUpdate.qry2.SQL.Text := Format('use %s select name from sys.views where type=''U'' ORDER BY name', [strUpdateDatabaseName]);
  frmUpdate.qry2.Open;

  frmUpdate.qry2.First;
  while not frmUpdate.qry2.Eof do
  begin
    Application.ProcessMessages;
    strViewName := frmUpdate.qry2.Fields[0].AsString;
    if frmUpdate.qry1.Locate('name', strViewName, []) then
    begin
      { �Ƚ�����ͼ�ṹ�Ƿ���ͬ }
      if not SameViewStructure(strOldDataBaseName, strUpdateDatabaseName, strViewName) then
      begin
        frmUpdate.LogInfo(Format('������ͼ��%s', [strViewName]));
        strTempTableName := 'db_temp_' + strViewName;
        strFields        := GetDataFields(strOldDataBaseName, strUpdateDatabaseName, strViewName);
        frmUpdate.qry4.Close;
        frmUpdate.qry4.SQL.Clear;
        frmUpdate.qry4.SQL.Text := Format(c_strSQL, [                                                     //
          strOldDataBaseName, strTempTableName, strUpdateDatabaseName, strViewName,                       // 1 ������ʱ����ͼ
          GetCreateKeyIndexSql(strOldDataBaseName, strUpdateDatabaseName, strTempTableName, strViewName), // 1 ��ʱ����ͼ�������������
          strOldDataBaseName, strTempTableName,                                                           // 2 ��������ʽֵ������ͼ�ı�ʶ����
          strOldDataBaseName, strTempTableName, strFields, strFields, strOldDataBaseName, strViewName,    // 2 ������ͼ���ݲ����µ���ʱ��ͼ
          strOldDataBaseName, strTempTableName,                                                           // 2 �رս���ʽֵ������ͼ�ı�ʶ����
          strOldDataBaseName, strViewName,                                                                // 3 ɾ������ͼ
          strOldDataBaseName, strTempTableName, strViewName                                               // 4 ����ʱ����ͼ������Ϊ����ͼ��
          ]);
        try
          frmUpdate.qry4.ExecSQL;
        except
          on E: Exception do
          begin
            frmUpdate.LogInfo(Format('������ͼʧ�ܡ���ͼ��: %s��ԭ��: %s', [strViewName, E.Message]));
            frmUpdate.LogInfo(frmUpdate.qry4.SQL.Text);
          end;
        end;
      end;
    end;
    frmUpdate.qry2.Next;
  end;
end;

end.
