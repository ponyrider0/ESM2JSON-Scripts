{
  ESM 2 JSON exporter.
}
unit esm2json_exporter;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
  Result := 0;

  PrintElementTypes();
  PrintVarTypes();

end;


procedure PrintVarTypes;
begin
  AddMessage('');
  AddMessage('varEmpty: ' + IntToStr(varEmpty));
  AddMessage('varNull: ' + IntToStr(varNull));
  AddMessage('varSmallint: ' + IntToStr(varSmallint));
  AddMessage('varInteger: ' + IntToStr(varInteger));
  AddMessage('varSingle: ' + IntToStr(varSingle));
  AddMessage('varDouble: ' + IntToStr(varDouble));
  AddMessage('varCurrency: ' + IntToStr(varCurrency));
  AddMessage('varDate: ' + IntToStr(varDate));
  AddMessage('varOleStr: ' + IntToStr(varOleStr));
  AddMessage('varDispatch: ' + IntToStr(varDispatch));
  AddMessage('varError: ' + IntToStr(varError));
  AddMessage('varBoolean: ' + IntToStr(varBoolean));
  AddMessage('varVariant: ' + IntToStr(varVariant));
  AddMessage('varUnknown: ' + IntToStr(varUnknown));
  AddMessage('varShortInt: ' + IntToStr(varShortInt));
  AddMessage('varByte: ' + IntToStr(varByte));
  AddMessage('varWord: ' + IntToStr(varWord));
  AddMessage('varLongWord: ' + IntToStr(varLongWord));
  AddMessage('varInt64: ' + IntToStr(varInt64));
  AddMessage('varStrArg: ' + IntToStr(varStrArg));
  AddMessage('varString: ' + IntToStr(varString));
  AddMessage('varAny: ' + IntToStr(varAny));
  AddMessage('');

end;


procedure PrintElementTypes;
begin
  AddMessage('');
  AddMessage('DEBUG: Constants:');
  AddMessage('etFile: ' + IntToStr(etFile));
  AddMessage('etMainRecord: ' + IntToStr(etMainRecord));
  AddMessage('etGroupRecord: ' + IntToStr(etGroupRecord));
  AddMessage('etSubRecord: ' + IntToStr(etSubRecord));
  AddMessage('etSubRecordStruct: ' + IntToStr(etSubRecordStruct));
  AddMessage('etSubRecordArray: ' + IntToStr(etSubRecordArray));
  AddMessage('etSubRecordUnion: ' + IntToStr(etSubRecordUnion));
  AddMessage('etArray: ' + IntToStr(etArray));
  AddMessage('etStruct: ' + IntToStr(etStruct));
  AddMessage('etValue: ' + IntToStr(etValue));
  AddMessage('etFlag: ' + IntToStr(etFlag));
  AddMessage('etStringListTerminator: ' + IntToStr(etStringListTerminator));
  AddMessage('etUnion: ' + IntToStr(etUnion));
  AddMessage('etStructChapter: ' + IntToStr(etStructChapter));
  AddMessage('');

end;


function IsReference(e: IInterface): boolean;
var
  sig: string;
begin
  sig := Signature(e);
  if ( (sig = 'ACHR') Or (sig = 'REFR') Or (sig = 'ACRE') ) then
  begin
    Result := True;
  end
  else begin
    Result := False;
  end;

end;


function ProcessChild(e: IInterface; prefix: string; postfix: string): integer;
var
  element: IInterface;
  native_type, element_count, element_index, child_count: integer;
  element_name, type_string, element_path, element_edit_value, prefix2, postfix2: string;
  native_value: Variant;
  parent_type, element_type: TwbElementType;
begin
  prefix2 := '    ';

  parent_type := ElementType(e);
  if ((parent_type = etArray) Or (parent_type = etSubRecordArray)) then
  begin
    AddMessage(prefix + '[');
  end
  else begin
    AddMessage(prefix + '{');
  end;

  element_count := ElementCount(e);
  for element_index := 0 to element_count-1 do
  begin
    postfix2 := '';
    if (element_index <> element_count-1) then postfix2 := ',';

    element := ElementByIndex(e, element_index);
    element_name := Name(element);
    element_path := Path(element);
    child_count := ElementCount(element);
    element_type := ElementType(element);
    element_edit_value := '"' + GetEditValue(element) + '"';
    native_value := GetNativeValue(element);
    native_type := VarType(native_value);

    type_string := '';
    // DEBUGGING
//  type_string := '[' + IntToStr(element_type) + ']';

//  if ( (element_type = etValue) or (element_type = etFlag) or (element_type = etSubRecord)) then
    if (child_count = 0) then
    begin
//      if (element_type = etFlag) then element_edit_value := IntToHex(native_value, 8) + '!!!';
//      if (VarType(native_value) = varLongWord) then element_edit_value := IntToHex(native_value, 8);
      if (native_type = 258) then
      begin
        element_edit_value := StringReplace(native_value,'\','\\', [rfReplaceAll]);
        element_edit_value := StringReplace(element_edit_value,'"','\"', [rfReplaceAll]);
        element_edit_value := StringReplace(element_edit_value, #13#10, '\r\n', [rfReplaceAll]);
        element_edit_value := StringReplace(element_edit_value, #10, '\n', [rfReplaceAll]);
        element_edit_value := '"' + element_edit_value + '"'
      end
      else if (native_type = varDouble) then
      begin
        element_edit_value := FloatToStrF(native_value, 2, 15, 15);
      end
      else if (native_type = varBoolean) then
      begin
        if (native_value) then begin
          element_edit_value := 'true';
        end else
        begin
          element_edit_value := 'false';
        end;
      end
      else if (native_type = varLongWord) then
      begin
        element_edit_value := '"' + IntToHex(native_value, 8) + 'H"';
      end
      else if (native_type = varWord) then
      begin
        element_edit_value := '"' + IntToHex(native_value, 4) + 'H"';
      end
      else if (varByte = varLongWord) then
      begin
        element_edit_value := '"' + IntToHex(native_value, 2) + 'H"';
      end;

      // Display as: "EDID" [FormID]
//      if (Pos('FormID', element_path) <> 0) then element_edit_value := IntToHex(native_value, 8);

      if (Pos('Flags', element_name) <> 0) then element_edit_value := '"' + IntToHex(native_value, 8) + 'H"';

      if (Pos('Value', element_name) = 1) then element_edit_value := IntToStr(native_value);
      if (Pos('Data Size', element_path) <> 0) then element_edit_value := IntToStr(native_value);

      if (Pos('EFID - Magic effect name', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + '"';
      if (Pos('Magic effect name', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + '"';
      if (CompareText('ENIT - ENIT \ Flags', element_path) = 0) then element_edit_value := '"' + IntToHex(native_value, 2) + 'H"';
      if (Pos('EFIT - EFIT \ Magnitude', element_path) <> 0) then element_edit_value := IntToStr(native_value);
      if (Pos('EFIT - EFIT \ Area', element_path) <> 0) then element_edit_value := IntToStr(native_value);
      if (Pos('EFIT - EFIT \ Duration', element_path) <> 0) then element_edit_value := IntToStr(native_value);
      if (Pos('EFIT - EFIT \ Type', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
      if (Pos('EFIT - EFIT \ Actor Value', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';

      if (Pos('Primary Attribute', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
      if (Pos('Major Skill', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
      if (Pos('Specialization', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
      if (Pos('Teaches', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';

      if (Pos('Skill Boost \ Skill', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
      if (Pos('Skill Boost \ Boost', element_path) <> 0) then element_edit_value := IntToStr(native_value);
      if (Pos('RACE \ ATTR - Base Attributes', element_path) <> 0) then element_edit_value := IntToStr(native_value);
      if (Pos('Body Data \ Parts \ Part \ INDX - Index', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
      if (Pos('Face Data \ Parts \ Part \ INDX - Index', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';


//      AddMessage('DEBUG: VarType=' + VarToStr(VarType(native_value)));
      AddMessage(prefix + prefix2 + type_string + '"' + element_name + '": ' + element_edit_value + postfix2);
    end
    else
    begin
      if ( (parent_type <> etSubRecordArray) And (parent_type <> etArray) )then
      begin
        if (Pos('Flags', element_path) <> 0) then
        begin
          element_edit_value := '"' + IntToHex(native_value, 8) + 'H"';
          if (Pos('ENIT - ENIT \ Flags', element_path) <> 0) then element_edit_value := '"' + IntToHex(native_value, 2) + 'H"';
          AddMessage(prefix + prefix2 + type_string + '"' + element_name + '": ' + element_edit_value );
        end
        else
        begin
  //        AddMessage('TEST');
          AddMessage(prefix + prefix2 + type_string + '"' + element_name + '":');
        end;
      end;
    end;

//    if (Assigned(element_type)) then AddMessage('DEBUG: ElementType: ' + IntToStr(element_type));
    if (child_count > 0) then ProcessChild(element, prefix + prefix2, postfix2);

  end;

  if ((parent_type = etArray) Or (parent_type = etSubRecordArray)) then
  begin
    AddMessage(prefix + ']' + postfix);
  end
  else begin
    AddMessage(prefix + '}' + postfix);
  end;

end;

// NOTES:
//   Path ==> hardcode for only DIAL, CELL and WRLD to have subdirs
//   General Case:
//     1. Filename: Morrowind_ob.esm
//     2. Signature: 'XXXX'
//     3. FormID: <FormID>.json
//  DIAL:
//     1. Filename
//     2. Signature
//     3. Topic FormID: <XXXX>
//     4. INFO FormID: <XXXX>.json
//  CELL:
//     1. Filename
//     2. Signature
//     3. Block XX
//     4. Sub-Block XX
//     5. Cell FormID: <XXXX>
//     6. Persistent / Temporary / VWD Children
//     7. REF / PGRD FormID: <XXXX>.json
//  WRLD:
//     1. Filename
//     2. Signature
//     3. WRLD FormID: <XXXX>
//   **4. Persistent CELL:
//        5. Persistent / Temporary? / VWD Children
//        6. REF / PGRD? FormID: <XXXX>.json
//   **4. Block XX
//        5. Sub-Block XX
//        6. CELL FormID: <XXXX>
//        7. Persistent/ Temporary / VWD Children
//        8. REF / LAND / PGRD FormID: <XXXX>.json

// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
  element, parent: IInterface;
  string_offset, element_count, element_index, child_count: integer;
  element_path, element_edit_value, prefix: string;
  sig, x_string, parent_path, parent_basename: string;
  parent_type: TwbElementType;
begin
  Result := 0;

  prefix := '    ';

  // comment this out if you don't want those messages
  AddMessage('Processing: ' + Name(e));

//  AddMessage('DEBUG: PathName(): ' + PathName(e));
//  AddMessage('DEBUG: FullPath(): ' + FullPath(e));

// ==> if element_type == Container <===
  // 1. If basename starts with 'GRUP Cell ...'
      // 2. Then If '...Children of [' Then record CELL:<FormID>
      // 3. Else If '...Persistent Children' Then record 'Persistent'
      // 4. Else If '...Temporary...' Then ...
      // 5. Else If '...Visible...' Then ...
  // 6. Else if starts with 'GRUP Interior Cell ' ...
  // 7. Else if starts with 'GRUP Exterior Cell ' ...
  // 8. Else if starts with 'GRUP World Children ' ...
  // 9. Else if starts with 'GRUP Top "' ...

//  element_path := '{' + Path(e) + '}';
  parent := GetContainer(e);
  element_path := IntToHex(GetLoadOrderFormID(e),8) + '.json';
  while (Assigned(parent)) do
    begin
      parent_type := ElementType(parent);
      parent_basename := BaseName(parent);
//      AddMessage('DEBUG: Container: [' + BaseName(parent) + ']: Type:'  + IntToStr(parent_type) );
      if (parent_type = etGroupRecord) then
      begin
        // 1. If basename starts with 'GRUP Cell ...'
        parent_path := parent_basename;
        if (Pos('GRUP Topic Children',parent_basename) = 1) then
        begin
          string_offset := Pos('[DIAL:', parent_basename) + 6;
          parent_path := copy(parent_basename, string_offset, 8);
        end
        else if (Pos('GRUP Cell',parent_basename) = 1) then
        begin
          // 2. Then If '...Children of [' Then record CELL:<FormID>
          if (Pos('GRUP Cell Children',parent_basename) = 1) then
          begin
            // Cell FORMID
            string_offset := Pos('[CELL:', parent_basename) + 6;
            parent_path := copy(parent_basename, string_offset, 8);
//            parent_path := IntToHex(GetLoadOrderFormID(e),8);
          end
          // 3. Else If '...Persistent Children' Then record 'Persistent'
          else if (Pos('GRUP Cell Persistent',parent_basename) = 1) then
          begin
            parent_path := 'Persistent';
          end
          // 4. Else If '...Temporary...' Then ...
          else if (Pos('GRUP Cell Temporary',parent_basename) = 1) then
          begin
            parent_path := 'Temporary';
          end
          // 5. Else If '...Visible...' Then ...
          else if (Pos('GRUP Cell Visible',parent_basename) = 1) then
          begin
            parent_path := 'Visible When Distant';
          end;
        end
        // 6. Else if starts with 'GRUP Interior Cell ' ...
        else if (Pos('GRUP Interior Cell',parent_basename) = 1) then
        begin
          if (Pos('GRUP Interior Cell Sub-Block',parent_basename) = 1) then
          begin
            string_offset := Length(parent_basename);
            x_string := copy(parent_basename, 29, string_offset);
            parent_path := 'Sub-Block ' + x_string;
          end
          else if (Pos('GRUP Interior Cell Block',parent_basename) = 1) then
          begin
            string_offset := Length(parent_basename);
            x_string := copy(parent_basename, 25, string_offset);
            parent_path := 'Block ' + x_string
          end;
        end
        // 7. Else if starts with 'GRUP Exterior Cell ' ...
        else if (Pos('GRUP Exterior Cell',parent_basename) = 1) then
        begin
          if (Pos('GRUP Exterior Cell Sub-Block',parent_basename) = 1) then
          begin
            string_offset := Length(parent_basename);
            x_string := copy(parent_basename, 29, string_offset);
            parent_path := 'Sub-Block ' + x_string;
          end
          else if (Pos('GRUP Exterior Cell Block',parent_basename) = 1) then
          begin
            string_offset := Length(parent_basename);
            x_string := copy(parent_basename, 25, string_offset);
            parent_path := 'Block ' + x_string
          end;
        end
        // 8. Else if starts with 'GRUP World Children ' ...
        else if (Pos('GRUP World Children',parent_basename) = 1) then
        begin
            // worldspace FORMID
            string_offset := Pos('[WRLD:', parent_basename) + 6;
            parent_path := copy(parent_basename, string_offset, 8);
        end
        // 9. Else if starts with 'GRUP Top "' ...
        else if (Pos('GRUP Top ',parent_basename) = 1) then
        begin
          sig := Signature(e);
          if ( (sig = 'INFO') Or (CompareText(sig, 'LAND')=0) Or (CompareText(sig, 'PGRD')=0) Or (IsReference(e)) ) then
          begin
            parent_path := copy(parent_basename, 11, 4);
          end
          else
          begin
            parent_path := sig;
          end;

        end;
      end
      // Not GroupRecord
      else if (parent_type = etFile) then
      begin
        parent_path := parent_basename;
      end;
      element_path := parent_path + '\' + element_path;
      parent := GetContainer(parent);
    end;
  AddMessage('DEBUG: composed path: ' + element_path);

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
