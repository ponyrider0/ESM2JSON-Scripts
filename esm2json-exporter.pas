{
  ESM 2 JSON exporter.
}
unit esm2json_exporter;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
  Result := 0;
end;


function ProcessChild(e: IInterface; prefix: string; postfix: string): integer;
var
  element: IInterface;
  element_count, element_index, child_count: integer;
  element_path, element_edit_value, prefix2, postfix2: string;
  native_value: Variant;
  element_type: TwbElementType;
begin
  prefix2 := prefix;
  if (prefix = '') then prefix2 := '    ';

  AddMessage(prefix + '{');
  element_count := ElementCount(e);
  for element_index := 0 to element_count-1 do
    begin
      postfix2 := '';
      if (element_index <> element_count-1) then postfix2 := ',';

      element := ElementByIndex(e, element_index);
      element_path := Name(element);
      child_count := ElementCount(element);
      element_type := ElementType(element);
//      if ( (element_type = etValue) or (element_type = etFlag) or (element_type = etSubRecord)) then
      if (child_count = 0) then
        begin
          element_edit_value := GetEditValue(element);
          native_value := GetNativeValue(element);
          if (Pos(element_path, 'FormID') <> 0) then element_edit_value := IntToHex(native_value, 8);
//          if (element_type = etFlag) then element_edit_value := IntToHex(native_value, 8) + '!!!';
//          if (VarType(native_value) = varLongWord) then element_edit_value := IntToHex(native_value, 8);
	        if (VarType(native_value) = 258) then element_edit_value := StringReplace(native_value,'\','\\', [rfReplaceAll]);
//          element_edit_value := VarToStr(native_value);
//          AddMessage('DEBUG: VarType=' + VarToStr(VarType(native_value)));
          AddMessage(prefix + prefix2 + '"' + element_path + '": "' + element_edit_value + '"' + postfix2);
        end
      else
        begin
          AddMessage(prefix + prefix2 + '"' + element_path + '":');
        end;

      if (child_count > 0) then ProcessChild(element, prefix + prefix2, postfix2);

    end;
  AddMessage(prefix + '}' + postfix);

end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
  element: IInterface;
  element_count, element_index, child_count: integer;
  element_path, element_edit_value, prefix: string;
begin
  Result := 0;

  prefix := '    ';

  // comment this out if you don't want those messages
  AddMessage('Processing: ' + FullPath(e));
  AddMessage('');

  // processing code goes here
  ProcessChild(e, '', '');

  AddMessage('');

end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
begin
  Result := 0;
end;

end.
