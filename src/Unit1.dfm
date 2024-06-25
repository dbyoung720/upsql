object frmUpdate: TfrmUpdate
  Left = 0
  Top = 0
  Caption = 'frmUpdate'
  ClientHeight = 518
  ClientWidth = 776
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    776
    518)
  PixelsPerInch = 96
  TextHeight = 13
  object lbl1: TLabel
    Left = 20
    Top = 20
    Width = 184
    Height = 16
    Caption = '1'#12289#35201#21319#32423#30340#25968#25454#24211#21517#31216#65306
    Font.Charset = GB2312_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
  end
  object lbl2: TLabel
    Left = 20
    Top = 57
    Width = 184
    Height = 16
    Caption = '2'#12289#26032#30340#25968#25454#24211#22791#20221#25991#20214#65306
    Font.Charset = GB2312_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
  end
  object btnSelect: TSpeedButton
    Left = 743
    Top = 54
    Width = 23
    Height = 22
    Hint = #36873#25321' *.bak '#25968#25454#24211#22791#20221#25991#20214
    Anchors = [akTop, akRight]
    ParentShowHint = False
    ShowHint = True
    OnClick = btnSelectClick
  end
  object cbbLibrary: TComboBox
    Left = 210
    Top = 17
    Width = 555
    Height = 24
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    DropDownCount = 20
    Font.Charset = GB2312_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnChange = cbbLibraryChange
  end
  object edtBakFileName: TEdit
    Left = 210
    Top = 54
    Width = 527
    Height = 24
    Hint = '*.bak '#25968#25454#24211#22791#20221#25991#20214
    Anchors = [akLeft, akTop, akRight]
    Font.Charset = GB2312_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
  end
  object btnUpdate: TButton
    Left = 20
    Top = 96
    Width = 745
    Height = 77
    Anchors = [akLeft, akTop, akRight]
    Caption = '3'#12289#24320#22987#21319#32423
    Enabled = False
    Font.Charset = GB2312_CHARSET
    Font.Color = clBlack
    Font.Height = -19
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = btnUpdateClick
  end
  object mmoLog: TMemo
    Left = 20
    Top = 188
    Width = 745
    Height = 313
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = GB2312_CHARSET
    Font.Color = clBlack
    Font.Height = -19
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 3
  end
  object con1: TADOConnection
    LoginPrompt = False
    Left = 52
    Top = 396
  end
  object qry1: TADOQuery
    Connection = con1
    Parameters = <>
    Left = 108
    Top = 396
  end
  object dlgOpen1: TOpenDialog
    Filter = '(*.bak)|*.bak'
    Title = #36873#25321' *.bak '#25968#25454#24211#22791#20221#25991#20214
    Left = 364
    Top = 120
  end
  object qry2: TADOQuery
    Connection = con1
    Parameters = <>
    Left = 164
    Top = 396
  end
  object qry3: TADOQuery
    Connection = con1
    Parameters = <>
    Left = 220
    Top = 396
  end
  object qry4: TADOQuery
    Connection = con1
    Parameters = <>
    Left = 276
    Top = 396
  end
end
