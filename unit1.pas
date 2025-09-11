unit unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  { TForm1 }
  TForm1 = class(TForm)
    btnSelectFile: TButton;
    btnOK: TButton;
    btnExit: TButton;
    btnSelectOddFile: TButton;
    btnSelectEvenFile: TButton;
    btnMerge: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    CheckBox1: TCheckBox;
    procedure btnExitClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnSelectFileClick(Sender: TObject);
    procedure btnSelectOddFileClick(Sender: TObject);
    procedure btnSelectEvenFileClick(Sender: TObject);
    procedure btnMergeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label4Click(Sender: TObject);
  private
    FSelectedFile, FOddFile, FEvenFile: string;
    procedure SplitFile(const FileName: string);
    procedure MergeFiles(const FirstFileName, SecondFileName: string);
    procedure LogMessage(const Msg: string);
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  FSelectedFile := '';
  FOddFile := '';
  FEvenFile := '';
  Memo1.Clear;
  LogMessage('Application started.');
end;

procedure TForm1.Label4Click(Sender: TObject);
begin

end;

procedure TForm1.LogMessage(const Msg: string);
begin
  Memo1.Lines.Add(DateTimeToStr(Now) + ': ' + Msg);
  Memo1.Lines.Add(''); // Add a blank line
end;

procedure TForm1.btnExitClick(Sender: TObject);
begin
  LogMessage('Exiting application.');
  Application.Terminate;
end;

procedure TForm1.btnSelectFileClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    FSelectedFile := OpenDialog1.FileName;
    LogMessage('Selected file to split: ' + FSelectedFile);
  end;
end;

procedure TForm1.btnOKClick(Sender: TObject);
begin
  if FSelectedFile <> '' then
  begin
    SplitFile(FSelectedFile);
    LogMessage('File split completed.');
  end
  else
    LogMessage('Error: No file selected to split.');
end;

procedure TForm1.SplitFile(const FileName: string);
var
  InFile, OutFileFirst, OutFileSecond: File;
  Counter: Int64;
  Buffer: array[0..1023] of Byte;
  BytesRead: LongInt;
  FirstFileName, SecondFileName: string;
begin
  if CheckBox1.Checked then
  begin
    FirstFileName := ChangeFileExt(FileName, '_odd.bin');
    SecondFileName := ChangeFileExt(FileName, '_even.bin');
  end
  else
  begin
    FirstFileName := ChangeFileExt(FileName, '_first.bin');
    SecondFileName := ChangeFileExt(FileName, '_second.bin');
  end;

  AssignFile(InFile, FileName);
  AssignFile(OutFileFirst, FirstFileName);
  AssignFile(OutFileSecond, SecondFileName);

  try
    Reset(InFile, 1);
    Rewrite(OutFileFirst, 1);
    Rewrite(OutFileSecond, 1);

    if CheckBox1.Checked then
    begin
      // Odd/Even split (AC|BD)
      LogMessage('Splitting using Odd/Even byte logic.');
      Counter := 0;
      while not Eof(InFile) do
      begin
        BlockRead(InFile, Buffer, 1, BytesRead);
        Counter := Counter + 1;
        if Odd(Counter) then
          BlockWrite(OutFileFirst, Buffer, BytesRead)
        else
          BlockWrite(OutFileSecond, Buffer, BytesRead);
      end;
      LogMessage('File split into odd/even bytes: ' + FirstFileName + ' and ' + SecondFileName);
    end
    else
    begin
      // First half/Second half split (AB|CD)
      LogMessage('Splitting using First half/Second half logic.');
      Counter := 0;
      while not Eof(InFile) do
      begin
        BlockRead(InFile, Buffer, 1, BytesRead);
        if Counter < FileSize(InFile) div 2 then
          BlockWrite(OutFileFirst, Buffer, BytesRead)
        else
          BlockWrite(OutFileSecond, Buffer, BytesRead);
        Counter := Counter + 1;
      end;
      LogMessage('File split into first/second half: ' + FirstFileName + ' and ' + SecondFileName);
    end;
  except
    on E: Exception do
      LogMessage('Error during split: ' + E.Message);
  end;

  CloseFile(InFile);
  CloseFile(OutFileFirst);
  CloseFile(OutFileSecond);
end;

procedure TForm1.btnSelectOddFileClick(Sender: TObject);
var
  FileName: string;
begin
  if CheckBox1.Checked then
    OpenDialog1.Title := 'Select Odd File'
  else
    OpenDialog1.Title := 'Select First File';

  if OpenDialog1.Execute then
  begin
    FileName := OpenDialog1.FileName;
    FOddFile := FileName;
    LogMessage('Selected first file: ' + FOddFile);
  end;
end;

procedure TForm1.btnSelectEvenFileClick(Sender: TObject);
var
  FileName: string;
begin
  if CheckBox1.Checked then
    OpenDialog1.Title := 'Select Even File'
  else
    OpenDialog1.Title := 'Select Second File';

  if OpenDialog1.Execute then
  begin
    FileName := OpenDialog1.FileName;
    FEvenFile := FileName;
    LogMessage('Selected second file: ' + FEvenFile);
  end;
end;

procedure TForm1.btnMergeClick(Sender: TObject);
begin
  if (FOddFile <> '') and (FEvenFile <> '') then
  begin
    MergeFiles(FOddFile, FEvenFile);
    LogMessage('Files merged successfully.');
  end
  else
    LogMessage('Error: Both files must be selected to merge.');
end;

procedure TForm1.MergeFiles(const FirstFileName, SecondFileName: string);
var
  InFileFirst, InFileSecond, OutFile: File;
  Buffer: array[0..1023] of Byte;
  BytesRead: LongInt;
  OutFileName: string;
begin
  OutFileName := ExtractFilePath(FirstFileName) + 'merged.bin';

  AssignFile(InFileFirst, FirstFileName);
  AssignFile(InFileSecond, SecondFileName);
  AssignFile(OutFile, OutFileName);

  try
    Reset(InFileFirst, 1);
    Reset(InFileSecond, 1);
    Rewrite(OutFile, 1);

    if CheckBox1.Checked then
    begin
      // Odd/Even merge (AC + BD)
      LogMessage('Merging using Odd/Even byte logic.');
      while (not Eof(InFileFirst)) or (not Eof(InFileSecond)) do
      begin
        if not Eof(InFileFirst) then
        begin
          BlockRead(InFileFirst, Buffer, 1, BytesRead);
          BlockWrite(OutFile, Buffer, BytesRead);
        end;
        if not Eof(InFileSecond) then
        begin
          BlockRead(InFileSecond, Buffer, 1, BytesRead);
          BlockWrite(OutFile, Buffer, BytesRead);
        end;
      end;
    end
    else
    begin
      // First half/Second half merge (AB + CD)
      LogMessage('Merging using First half/Second half logic.');
      while not Eof(InFileFirst) do
      begin
        BlockRead(InFileFirst, Buffer, SizeOf(Buffer), BytesRead);
        BlockWrite(OutFile, Buffer, BytesRead);
      end;
      while not Eof(InFileSecond) do
      begin
        BlockRead(InFileSecond, Buffer, SizeOf(Buffer), BytesRead);
        BlockWrite(OutFile, Buffer, BytesRead);
      end;
    end;

    LogMessage('Files merged into: ' + OutFileName);
  except
    on E: Exception do
      LogMessage('Error during merge: ' + E.Message);
  end;

  CloseFile(InFileFirst);
  CloseFile(InFileSecond);
  CloseFile(OutFile);
end;

end.

