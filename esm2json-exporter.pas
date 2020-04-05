{
  ESM 2 JSON exporter.
}
unit esm2json_exporter;

var
  json_output: TStringList;
  json_filecount: integer;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
  Result := 0;

  json_output := TStringList.Create;
//  PrintElementTypes();
//  PrintVarTypes();

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


function GetFormIDLabel(e: IInterface; formid: Cardinal): string;
var
  name_string: string;
  base_formID: Cardinal;
  base_record, target_record: IInterface;
begin

  target_record := RecordByFormID(GetFile(e), formid, True);
  name_string := EditorID(target_record);
  if ( (name_string = '') And (IsReference(target_record)) ) then
  begin
    name_string := '(' + Signature(target_record) + ')';
    // base_formID := GetElementNativeValues(target_record, 'Name - Base');
    // AddMessage('DEBUG: base_formID=' + IntToHex(base_formID, 8));
    // base_record := RecordByFormID(GetFile(e), base_formID, True);
    // if (Assigned(base_record)) then
    // begin
    //   name_string := 'BASE(' + EditorID(base_record) + ')';
    // end;
  end;
  Result := '"' + name_string + ':' + IntToHex(formid, 8) + 'H"';

end;


function FormatNativeValue(native_value: Variant; element_edit_value: string = ''): string;
var
  native_type: integer;
begin

  native_type := VarType(native_value);

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

  Result := element_edit_value;

end;


function ProcessSubRecord(e: IInterface; prefix: string; postfix: string): integer;
var
  element: IInterface;
  native_type, element_count, element_index, child_count: integer;
  element_name, type_string, element_path, element_edit_value, prefix2, postfix2: string;
  native_value: Variant;
  parent_type, element_type: TwbElementType;
  stringlist_length: integer;
begin
  prefix2 := '    ';

  parent_type := ElementType(e);
  if ((parent_type = etArray) Or (parent_type = etSubRecordArray)) then
  begin
//    json_output.append(prefix + '[');
    stringlist_length := json_output.Count;
    json_output[stringlist_length-1] := json_output[stringlist_length-1] + ' [';
  end
  else begin
//    json_output.append(prefix + '{');
    stringlist_length := json_output.Count;
    json_output[stringlist_length-1] := json_output[stringlist_length-1] + ' {';
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

//      AddMessage('DEBUG: element_path=' + element_path);
      if (Pos('Unused', element_path) = 0) then
      begin

        element_edit_value := FormatNativeValue(native_value, element_edit_value);

        // Display as: "EDID:FormID"
        if (Pos(' \ QSTI - Quest', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
//        if (Pos(' \ AI Packages \ PKID - AI Package', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
//        if (Pos(' \ SPLO - Spell', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos('CONT \ SNAM - Open sound', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos('CONT \ QNAM - Close sound', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
//        if (Pos(' \ CNTO - Item \ Item', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos('Weather Type \ Weather', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos('\ Door', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos('\ NAME - Base', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos('SCRI - Script', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos('ENAM - Enchantment', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos('DATA - IDLE animation', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);

        if (Pos('ANAM - Enchantment Points', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('Weather Type \ Chance', element_path) <> 0) then element_edit_value := IntToStr(native_value);
//        if (Pos('\ CNTO - Item \ Count', element_path) <> 0) then element_edit_value := IntToStr(native_value);

        if ( (Pos('EFIT - EFIT \ Type', element_path) <> 0) And (native_type <> 8209) ) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';

        if (Pos('Flags', element_name) <> 0) then element_edit_value := '"' + IntToHex(native_value, 8) + 'H"';
        if (CompareText('CELL \ DATA - Flags', element_path) = 0) then element_edit_value := '"' + IntToHex(native_value, 2) + 'H"';

        if (Pos('\ Value', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('Data Size', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('\ Damage', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('\ Armor', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('\ Health', element_path) <> 0) then element_edit_value := IntToStr(native_value);

        if (Pos('EFID - Magic effect name', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + '"';
        if (Pos('Magic effect name', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + '"';
        if (CompareText('ENIT - ENIT \ Flags', element_path) = 0) then element_edit_value := '"' + IntToHex(native_value, 2) + 'H"';
        if (Pos('EFIT - EFIT \ Magnitude', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('EFIT - EFIT \ Area', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('EFIT - EFIT \ Duration', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  //      if (Pos('EFIT - EFIT \ Type', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('EFIT - EFIT \ Actor Value', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('SCIT - Script effect data \ Script effect', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos('SCIT - Script effect data \ Magic school', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('SCIT - Script effect data \ Visual effect name', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';

        if (Pos('INFO \ Conditions \ CTDA - Condition \ Function', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        //if (Pos('INFO \ Conditions \ CTDA - Condition \ Parameter', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + '"';

        if (Pos('Primary Attribute', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('Major Skill', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('Specialization', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('Teaches', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';

        if (Pos('Skill Boost \ Skill', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('Skill Boost \ Boost', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('RACE \ ATTR - Base Attributes', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('Body Data \ Parts \ Part \ INDX - Index', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('Face Data \ Parts \ Part \ INDX - Index', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';

        if (Pos('QUST \ DATA - General \ Priority', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('Stage \ INDX - Stage index', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('SCHR - Basic Script Data \ RefCount', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('SCHR - Basic Script Data \ CompiledSize', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('SCHR - Basic Script Data \ VariableCount', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('SCHR - Basic Script Data \ Type', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('SCRO - Global Reference', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);

        if (Pos(' \ DATA - Point Count', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos(' \ Connections', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('PGRP - Points \ Point ', element_path) <> 0) then element_edit_value := IntToStr(native_value);

        if (Pos(' Color \ Red', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos(' Color \ Green', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos(' Color \ Blue', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('\ XCMT - Music', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('XCLL - Lighting \ Directional Rotation XY', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('XCLL - Lighting \ Directional Rotation Z', element_path) <> 0) then element_edit_value := IntToStr(native_value);
      end;

//      AddMessage('DEBUG: VarType=' + VarToStr(VarType(native_value)));
      json_output.append(prefix + prefix2 + type_string + '"' + element_name + '": ' + element_edit_value + postfix2);
    end
    // if child_count <> 0
    else
    begin
      json_output.append(prefix + prefix2 + type_string + '"' + element_name + '":');
    end;

//    if (Assigned(element_type)) then AddMessage('DEBUG: ElementType: ' + IntToStr(element_type));
    if (child_count > 0) then ProcessSubRecord(element, prefix + prefix2, postfix2);

  end;

  if ((parent_type = etArray) Or (parent_type = etSubRecordArray)) then
  begin
    json_output.append(prefix + ']' + postfix);
  end
  else begin
    json_output.append(prefix + '}' + postfix);
  end;

end;


function ProcessRecord(e: IInterface; prefix: string; postfix: string): integer;
var
  element: IInterface;
  native_type, element_count, element_index, child_count: integer;
  element_name, type_string, element_path, element_edit_value, prefix2, postfix2: string;
  native_value: Variant;
  parent_type, element_type: TwbElementType;
  stringlist_length: integer;
begin
  prefix2 := '    ';

  parent_type := ElementType(e);
  json_output.append(prefix + '{');

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

//      AddMessage('DEBUG: element_path=' + element_path);
      if (Pos('Unused', element_path) = 0) then
      begin

        element_edit_value := FormatNativeValue(native_value, element_edit_value);

        // MOVE TO SUBRECORD:
        // Record Header: Signature, Data Size, Record Flags, FormID, Version Control Info
        if (Pos(' \ Record Header \ Data Size', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // * \ Model \ *,
        // * \ BMDT - BMDT \ *
        // * \ XCLL - Lighting \ * (CELL)
        if (Pos(' \ XCLL - Lighting \ ', element_path) <> 0) then
        begin
          // * \ XCLL - Lighting \ *** Ambient OR Directional OR Fog *** Color \ Red Or Green Or Blue
          if (Pos(' Color \ Red', element_path) <> 0) then element_edit_value := IntToStr(native_value);
          if (Pos(' Color \ Green', element_path) <> 0) then element_edit_value := IntToStr(native_value);
          if (Pos(' Color \ Blue', element_path) <> 0) then element_edit_value := IntToStr(native_value);
          if (Pos(' \ XCLL - Lighting \ Directional Rotation XY', element_path) <> 0) then element_edit_value := IntToStr(native_value);
          if (Pos(' \ XCLL - Lighting \ Directional Rotation Z', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        end;
        // REFR \ XTEL - Teleport Destination \ Door
        if (Pos(' \ XTEL - Teleport Destination \ Door', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // PGRD \ PGRP - Points \ *
        // PGRD \ PGRP - Points \ Point #** \ X|Y|Z|Connections
        if (Pos(' \ PGRP - Points \ Point #', element_path) <> 0) then element_edit_value := IntToStr(native_value);
//        if (Pos(' \ Connections', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // PGRD \ PGRR - Point-to-Point Connections \ *
        // PGRD \ PGRR - Point-to-Point Connections \ Point #** \ Point
        if (Pos('PGRD \ PGRR - Point-to-Point Connections \ Point #', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // * \ DATA - DATA \ *
        if (Pos(' \ DATA - DATA \ Value', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos(' \ DATA - DATA \ Damage', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos(' \ DATA - DATA \ Armor', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos(' \ DATA - DATA \ Health', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // * \ DATA - DATA \ Type
        if (Pos(' \ DATA - DATA \ Type', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        // * \ DATA - DATA \ Teaches (BOOK)
        if (Pos(' \ DATA - DATA \ Teaches', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        // CLAS \ DATA - DATA \ Primary Attributes \ *
        if (Pos(' \ DATA - DATA \ Primary Attributes \ ', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
          // CLAS \ DATA - DATA \ Major Skills \ *
        if (Pos(' \ DATA - DATA \ Major Skill \ ', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
          // CLAS \ DATA - DATA \ Specialization
        if (Pos(' \ DATA - DATA \ Specialization', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        // CLAS \ DATA - DATA \ Buys/Sells and Services
        // CLAS \ DATA - DATA \ Teaches
        // CLAS \ DATA - DATA \ Maximum training level
        // CLMT \ WLST - Weather Types \ **
        if (Pos(' \ WLST - Weather Types \ Weather Type \ Weather', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos(' \ WLST - Weather Types \ Weather Type \ Chance', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // CLMT \ TNAM - Timing \ ** \ Begin|End
        // CLMT \ TNAM - Timing \ Volatility|Moons / Phase Length
        // CLOT \ *
        // * \ Items \ CNTO - Item \ * (CONT/CREA)
        if (Pos(' \ Items \ CNTO - Item \ Item', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos(' \ Items \ CNTO - Item \ Count', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // * \ Spells \ SPLO - Spell (CREA)
        if (Pos(' \ Spells \ SPLO - Spell', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // * \ ACBS - Configureation \ Base spell points|Fatigue|Barter gold|Level (offset)|Calc min|Calc max (CREA)
        // TODO: verify ==>
        if (Pos(' \ ACBS - Configureation \ ', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // * \ Factions \ SNAM - Faction (CREA)
        // * \ Factions \ SNAM - Faction \ Faction ==> FormID
        // * \ Factions \ SNAM - Faction \ Rank ==> int
        // * \ AIDT - AI Data \ * (CREA)
        // * \ AIDT - AI Data \ Aggression|Confidence|Energy Level|Responsibility|Maximum training level
        // ==> over-ride above
        // * \ AIDT - AI Data \ Teaches
        // TODO: verify ==>
        if (Pos(' \ AIDT - AI Data \ Teaches', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        // * \ AIDT - AI Data \ Buys/Sells and Services
        // * \ AI Packages \ PKID - AI Package (CREA)
        if (Pos(' \ AI Packages \ PKID - AI Package', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // CREA \ DATA - Creature Data \ *
        // CREA \ DATA - Creature Data \ Type ==> "Creature?"
        // CREA \ DATA - Creature Data \ Soul ==> "Common?"
        // ==> over-ride above
        // CREA \ DATA - Creature Data \ Combat Skill|Magic Skill|Stealth Skill|Health|Attack Damage|Strength|Intelligence|Willpower|Agility|Speed|Endurance|Personality|Luck
        // CSTY \ CSTD - Standard \ *
        // CSTY \ CSAD - Advanced \ *
        // INFO \ Responses \ *
        // INFO \ Responses \ TRDT - Response Data \ *
        // INFO \ Responses \ TRDT - Response Data \ Emotion Type
        // INFO \ Responses \ TRDT - Response Data \ Emotion Value
        // INFO \ Responses \ TRDT - Response Data \ Response number
        // INFO \ Responses \ NAM1 - Response Text => txt
        // INFO \ Responses \ NAM2 - Actor notes => txt
        // INFO \ Conditions \ CTDA - Condition \ *
        // INFO \ Conditions \ CTDA - Condition \ Type
        // INFO \ Conditions \ CTDA - Condition \ Function
        // INFO \ Conditions \ CTDA - Condition \ Parameter #1
        // INFO \ Conditions \ CTDA - Condition \ Paramater #2
        if (Pos('INFO \ Conditions \ CTDA - Condition \ Function', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        //if (Pos('INFO \ Conditions \ CTDA - Condition \ Parameter', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + '"';
        // INFO \ Result Script \ SCHR - Basic Script Data \ *
        // INFO \ Result Script \ SCHR - Basic Script Data \ Type
        // INFO \ Result Script \ SCHR - Basic Script Data \ RefCount|CompiledSize|VariableCount
        if (Pos(' \ Result Script \ SCHR - Basic Script Data \ RefCount', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos(' \ Result Script \ SCHR - Basic Script Data \ CompiledSize', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos(' \ Result Script \ SCHR - Basic Script Data \ VariableCount', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // over-ride above
        if (Pos(' \ Result Script \ SCHR - Basic Script Data \ Type', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        // INFO \ Result Script \ References \ SCRO - Global Reference
        if (Pos(' \ Result Script \ References \ SCRO - Global Reference', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // INFO \ Choices\ TCLT - Choice
        if (Pos('INFO \ Choices \ TCLT - Choice', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // * \ ENIT - ENIT \ * (ALCH,ENCH,INGR)
        // * \ ENIT - ENIT \ Charge Amount|Enchant Cost
        // * \ ENIT - ENIT \ Type
        if (Pos(' \ ENIT - ENIT \ Flags', element_path) = 0) then element_edit_value := '"' + IntToHex(native_value, 2) + 'H"';
        if (Pos(' \ ENIT - ENIT \ Value', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // * \ Effects \ Effect \ *
        if (Pos(' \ Effects \ Effect \ EFID - Magic effect name', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + '"';
        if (Pos(' \ Effects \ Effect \ EFIT - EFIT \ Magic effect name', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + '"';
        if (Pos(' \ Effects \ Effect \ EFIT - EFIT \ Magnitude', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos(' \ Effects \ Effect \ EFIT - EFIT \ Area', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos(' \ Effects \ Effect \ EFIT - EFIT \ Duration', element_path) <> 0) then element_edit_value := IntToStr(native_value);
//        if ( (Pos('EFIT - EFIT \ Type', element_path) <> 0) And (native_type <> 8209) ) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos(' \ Effects \ Effect \ EFIT - EFIT \ Type', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos(' \ Effects \ Effect \ EFIT - EFIT \ Actor Value', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos(' \ Effects \ Effect \ SCIT - Script effect data \ Script effect', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos(' \ Effects \ Effect \ SCIT - Script effect data \ Magic school', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos(' \ Effects \ Effect \ SCIT - Script effect data \ Visual effect name', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        // EYES \ DATA - Flags
        // FACT \ Relations \ XNAM - Relation \ *
        // FACT \ Relations \ XNAM - Relation \ Faction => formid
        // FACT \ Relations \ XNAM - Relation \ Modifier => int
        // FLOR \ PFPC - Seasonal ingredient production \ Spring|Summer|Fall|Winter => int
        // * \ DATA - DATA \ * (GRAS)
        // * \ DATA - DATA \ Density|Min Slope|Max Slope
        // * \ DATA - DATA \ Unit from water amount|Unit from water type
        // HAIR \ DATA - Flags ?
        // IDLE \ Conditions \ CTDA Condition \ *
        // IDLE \ Data - Related Idle Animations \ * ==> formid
        // LIGH \ DATA - DATA \ *
        // LIGH \ DATA - DATA \ Time
        // LIGH \ DATA - DATA \ Radius
        // LIGH \ DATA - DATA \ Color \ Red|Green|Blue
        // LTEX \ HNAM - Havok Data \ *
        // LTEX \ HNAM - Havok Data \ Material Type
        // LTEX \ HNAM - Havok Data \ Friction
        // LTEX \ HNAM - Havok Data \ Restitution
        // LTEX \ Grasses \ GNAM - Grass ==> formid
        // * \ Leveled List Entries \ LVLO - Leveled List Entry \ * (LVLC,LVLI)
        // * \ Leveled List Entries \ LVLO - Leveled List Entry \ Reference ==> formid
        // * \ Leveled List Entries \ LVLO - Leveled List Entry \ Level|Count
        // MISC \ DATA - DATA \ *
        // MISC \ DATA - DATA \ ????


        // ACTI - done
        // ALCH - done
        // AMMO - done
        // ANIO - done
        // APPA - done
        // ARMO - done
        // BOOK - done
        // CELL - done
        // ACHR - done
        // REFR - done
        // PGRD - done
        // CLAS - done
        // CLMT - done
        // CLOT - done
        // CONT - done
        // CREA - done
        // CSTY - done
        // DIAL -
        // INFO - done
        // DOOR - done
        // ENCH - done
        // EYES - done
        // FACT - done
        // FLOR - done
        // FURN - done
        // GLOB - done
        // INGR - done
        // KEYM - done
        // LTEX - done
        // LVLC - done
        // LVLI - done
        // MISC - done
        // NPC_ - 




        // GENERAL
        // * \ EDID - Editor ID, * \ FULL - Name, * \ SCRI - Script
        // * \ ENAM - Enchantment, * \ ANAM - Enchantment Points
        // BOOK \ DESC - Description
        if (Pos(' \ SCRI - Script', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos(' \ ENAM - Enchantment', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        if (Pos(' \ ANAM - Enchantment Points', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // * \ DATA - IDLE animation
        if (Pos(' \ DATA - IDLE animation', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // * \ XCMT - Music (CELL)
        if (Pos(' \ XCMT - Music', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        // * \ Name - Base (ACHR, REFR,)
        if (Pos(' \ NAME - Base', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // PGRD \ Data - Point Count
        if (Pos(' \ DATA - Point Count', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // * \ SNAM - Open sound (CONT,DOOR)
        if (Pos(' \ SNAM - Open sound', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // * \ QNAM - Close sound (CONT,DOOR)
        if (Pos(' \ QNAM - Close sound', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // CREA \ RNAM - Attack reach ==> int
        // TODO: ==> verify
        // CREA \ ZNAM - Combat Style ==> formid
        if (Pos(' \ ZNAM - Combat Style', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // CREA \ CSCR - Inherits Sounds from ==> formid
        if (Pos(' \ CSCR - Inherits Sounds from', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // INFO \ QSTI - Quest ==> formid
        if (Pos(' \ QSTI - Quest', element_path) <> 0) then element_edit_value := GetFormIDLabel(e, native_value);
        // INFO \ PNAM - Previous Info ==> formid
        // DOOR \ FNAM - Flags
        // FLOR \ PFIG - Ingredient ==> formid
        // FURN \ MNAM - Marker Flags ==> bytes
        // GLOB\ FNAM - Type
        // IDLE \ ANAM - Animation Group Section
        // LTEX \ SNAM - Texture Specular Exponent
        // * \ LVLD - Chance none (LVLC,LVLI)




        if (CompareText('CELL \ DATA - Flags', element_path) = 0) then element_edit_value := '"' + IntToHex(native_value, 2) + 'H"';

        if (Pos('Skill Boost \ Skill', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('Skill Boost \ Boost', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('RACE \ ATTR - Base Attributes', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('Body Data \ Parts \ Part \ INDX - Index', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        if (Pos('Face Data \ Parts \ Part \ INDX - Index', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';

        if (Pos('QUST \ DATA - General \ Priority', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        if (Pos('Stage \ INDX - Stage index', element_path) <> 0) then element_edit_value := IntToStr(native_value);


      end;

//      AddMessage('DEBUG: VarType=' + VarToStr(VarType(native_value)));
      json_output.append(prefix + prefix2 + type_string + '"' + element_path + '": ' + element_edit_value + postfix2);
    end
    // if child_count <> 0
    else
    begin
      json_output.append(prefix + prefix2 + type_string + '"' + element_path + '":');
    end;

//    if (Assigned(element_type)) then AddMessage('DEBUG: ElementType: ' + IntToStr(element_type));
    if (child_count > 0) then ProcessSubRecord(element, prefix + prefix2, postfix2);

  end;

  json_output.append(prefix + '}' + postfix);

end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
  element, parent: IInterface;
  string_offset, element_count, element_index, child_count: integer;
  element_filename, element_path, element_edit_value, prefix: string;
  sig, x_string, parent_path, parent_basename: string;
  parent_type: TwbElementType;
begin
  Result := 0;

  prefix := '    ';

//  AddMessage('Processing: ' + Name(e));

  parent := GetContainer(e);
  element_filename := IntToHex(GetLoadOrderFormID(e),8) + '.json';
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
          // sig := Signature(e);
          // if ( (sig = 'INFO') Or (CompareText(sig, 'LAND')=0) Or (CompareText(sig, 'PGRD')=0) Or (IsReference(e)) ) then
          // begin
          //   parent_path := copy(parent_basename, 11, 4);
          // end
          // else
          // begin
          //   parent_path := sig;
          // end;
          parent_path := copy(parent_basename, 11, 4);
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
//  AddMessage('DEBUG: composed path: ' + element_path);
//  AddMessage('');

  // processing code goes here
  json_filecount := json_filecount + 1;
  if (json_filecount mod 100 = 0) then AddMessage('INFO: ' + IntToStr(json_filecount) + ' files written...');
//  json_output := TStringList.Create;
  ProcessRecord(e, '', '');
  ForceDirectories(element_path);
  json_output.SaveToFile(element_path + element_filename);
//  json_output.Free;
  json_output.Clear;

//  AddMessage('');

end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
begin
  AddMessage('Script Complete.  ' + IntToStr(json_filecount) + ' json files written.');
  json_output.Free;
  Result := 0;
end;

end.
