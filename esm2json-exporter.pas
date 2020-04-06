{
  ESM 2 JSON exporter.
}
unit esm2json_exporter;

var
  json_output: TStringList;
  json_filecount: integer;
  target_mod_file: IwbFile;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
  Result := 0;

  json_output := TStringList.Create;
//  PrintElementTypes();
//  PrintVarTypes();

end;


// varEmpty: 0
// varNull: 1
// varSmallint: 2
// varInteger: 3
// varSingle: 4
// varDouble: 5
// varCurrency: 6
// varDate: 7
// varOleStr: 8
// varDispatch: 9
// varError: 10
// varBoolean: 11
// varVariant: 12
// varUnknown: 13
// varShortInt: 16
// varByte: 17
// varWord: 18
// varLongWord: 19
// varInt64: 20
// varStrArg: 72
// varString: 256
// varAny: 257
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

// etFile: 0
// etMainRecord: 1
// etGroupRecord: 2
// etSubRecord: 3
// etSubRecordStruct: 4
// etSubRecordArray: 5
// etSubRecordUnion: 6
// etArray: 7
// etStruct: 8
// etValue: 9
// etFlag: 10
// etStringListTerminator: 11
// etUnion: 12
// etStructChapter: 13
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


function ComposeFilePath(e:IInterface): string;
var
  file_path, parent_path, parent_basename: string;
  x_string: string;
  string_offset: integer;
  parent: IInterface;
  parent_type: TwbElementType;
begin

  parent := GetContainer(e);
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
          parent_path := copy(parent_basename, 11, 4);
        end;
      end
      // Not GroupRecord
      else if (parent_type = etFile) then
      begin
        parent_path := parent_basename;
      end;
      file_path := parent_path + '\' + file_path;
      parent := GetContainer(parent);
    end;

    Result := file_path;

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


function ReplaceEmptyFlagsString(element_path: string; native_value: Variant; element_edit_value: string=''): string;
begin

  if ( (Pos(' Flags', element_path) <> 0) ) then
  begin
    if (native_value = 0) then element_edit_value := '{}';
  end;

  Result := element_edit_value;

end;


function GetFormIDLabel(formid: Cardinal): string;
var
  name_string: string;
  base_formID: Cardinal;
  base_record, target_record: IInterface;
begin

  target_record := RecordByFormID(target_mod_file, formid, True);
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
  i, array_count: integer;
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
  else if (native_type = 8209) then
  begin
    array_count := Length(native_value)-1;
    for i := 0 to array_count do
    begin
      element_edit_value :=  element_edit_value + IntToHex(native_value[0],2);
      if (i <> array_count) then element_edit_value := element_edit_value + ' ';
    end;
    element_edit_value := '"' + element_edit_value + '"';
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


function ProcessCellRecords(element_path:string; native_value: Variant; element_edit_value:string ): string;
begin

  // * \ XCLL - Lighting \ * (CELL)
  // * \ XCLL - Lighting \ *** Ambient|Directional|Fog *** Color \ Red|Green|Blue
  // REGN \ RCLR - Map Color \ RED|Green|Blue
  if (Pos(' Color \ Red', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  if (Pos(' Color \ Green', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  if (Pos(' Color \ Blue', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  if (Pos(' \ XCLL - Lighting \ Directional Rotation XY', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  if (Pos(' \ XCLL - Lighting \ Directional Rotation Z', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  // REFR \ XTEL - Teleport Destination \ Door
  if (Pos(' \ XTEL - Teleport Destination \ Door', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
  // PGRD \ PGRP - Points \ *
  // PGRD \ PGRP - Points \ Point #** \ X|Y|Z|Connections
  if (Pos(' \ PGRP - Points \ Point #', element_path) <> 0) then element_edit_value := IntToStr(native_value);
//        if (Pos(' \ Connections', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  // PGRD \ PGRR - Point-to-Point Connections \ *
  // PGRD \ PGRR - Point-to-Point Connections \ Point #** \ Point
  if (Pos('PGRD \ PGRR - Point-to-Point Connections \ Point #', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  // WRLD \ MNAM - Map Data \ *
  // WRLD \ MNAM - Map Data \ Usable Dimensions \ X|Y
  // WRLD \ MNAM - Map Data \ Cell Coordinates \ ** NW|SE ** Cell \ X|Y
  // CELL \ XCLC - Grid \ X|Y
  // CELL \ XCLR - Regions \ Region ==> formid
  // LAND \ Layers \ *
  // LAND \ Layers \ *** Base|Alpha *** Layer \ *** BTXT|ATXT *** ... \ *
  // LAND \ Layers \ *** Base|Alpha *** Layer \ *** BTXT|ATXT *** ... \ Texture ==> formid
  // LAND \ Layers \ *** Base|Alpha *** Layer \ *** BTXT|ATXT *** ... \ Quadrant
  // LAND \ Layers \ *** Base|Alpha *** Layer \ *** BTXT|ATXT *** ... \ Layer
  // LAND \ Layers \ *** Base|Alpha *** Layer \ VTXT ...

  Result := element_edit_value;

end;



function ProcessNonCellRecords(element: IInterface; element_path:string; native_value: Variant; element_edit_value:string ): string;
begin

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
  if (Pos(' \ WLST - Weather Types \ Weather Type \ Weather', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
  if (Pos(' \ WLST - Weather Types \ Weather Type \ Chance', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  // CLMT \ TNAM - Timing \ ** \ Begin|End
  // CLMT \ TNAM - Timing \ Volatility|Moons / Phase Length
  // CLOT \ *
  // * \ Items \ CNTO - Item \ * (CONT,CREA,NPC_)
  if (Pos(' \ Items \ CNTO - Item \ Item', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
  if (Pos(' \ Items \ CNTO - Item \ Count', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  // * \ Spells \ SPLO - Spell (CREA,NPC_,RACE)
  if (Pos(' \ Spells \ SPLO - Spell', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
  // * \ ACBS - Configuration \ *
  // * \ ACBS - Configuration \ Base spell points|Fatigue|Barter gold|Level (offset)|Calc min|Calc max (CREA, NPC_)
  // * \ ACBS - Configuration \ Flags
  // TODO: verify ==>
  if (Pos(' \ ACBS - Configureation \ ', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  // * \ Factions \ SNAM - Faction (CREA, NPC_)
  // * \ Factions \ SNAM - Faction \ Faction ==> FormID
  // * \ Factions \ SNAM - Faction \ Rank ==> int
  // * \ AIDT - AI Data \ * (CREA, NPC_)
  // * \ AIDT - AI Data \ Aggression|Confidence|Energy Level|Responsibility|Maximum training level
  // ==> over-ride above
  // * \ AIDT - AI Data \ Teaches
  // TODO: verify ==>
  if (Pos(' \ AIDT - AI Data \ Teaches', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
  // * \ AIDT - AI Data \ Buys/Sells and Services
  // * \ AI Packages \ PKID - AI Package (CREA)
  if (Pos(' \ AI Packages \ PKID - AI Package', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
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
  // * \ Conditions \ CTDA - Condition \ * (INFO, IDLE, PACK, QUST)
  // * \ Conditions \ CTDA - Condition \ Type
  // * \ Conditions \ CTDA - Condition \ Function
  // * \ Conditions \ CTDA - Condition \ Parameter #1
  // * \ Conditions \ CTDA - Condition \ Paramater #2
  if (Pos(' \ Conditions \ CTDA - Condition \ Function', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
  //if (Pos(' \ Conditions \ CTDA - Condition \ Parameter', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + '"';
  // * \ Result Script \ SCHR - Basic Script Data \ * (INFO, QUST\Stages\LogEntries\LogEntry\ResultScript,)
  // * \ Result Script \ SCHR - Basic Script Data \ Type
  // * \ Result Script \ SCHR - Basic Script Data \ RefCount|CompiledSize|VariableCount
  // SCPT \ SCHR - Basic Script Data \ *
  if (Pos(' \ SCHR - Basic Script Data \ RefCount', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  if (Pos(' \ SCHR - Basic Script Data \ CompiledSize', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  if (Pos(' \ SCHR - Basic Script Data \ VariableCount', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  // over-ride above
  if (Pos(' \ SCHR - Basic Script Data \ Type', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
  // INFO \ Result Script \ References \ SCRO - Global Reference
  // SCPT \ References \ SCRO - Global Reference
  if (Pos(' \ References \ SCRO - Global Reference', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
  // INFO \ Choices\ TCLT - Choice
  if (Pos('INFO \ Choices \ TCLT - Choice', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
  // * \ ENIT - ENIT \ * (ALCH,ENCH,INGR)
  // * \ ENIT - ENIT \ Charge Amount|Enchant Cost
  // * \ ENIT - ENIT \ Type
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
  if (Pos(' \ Effects \ Effect \ SCIT - Script effect data \ Script effect', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
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
  // NPC_ \ DATA - Stats \ *
  // NPC_ \ DATA - Stats \ Armorer|Athletics|Blade|Block|Blunt|Hand to Hand|Heavy Armor|Alchemy|...
  // NPC_ \ HCLR - Hair color \ *
  // NPC_ \ HCLR - Hair color \ Red|Green|Blue
  // * \ FaceGen Data \ * (NPC_, RACE)
  // * \ FaceGen Data \ FGGS - ...
  // * \ FaceGen Data \ FGGA - ...
  // * \ FaceGen Data \ FGTS - ...
  // PACK \ PKDT - General \ General \ *
  // PACK \ PKDT - General \ General \ Type
  // PACK \ PLDT - Location \ *
  // PACK \ PLDT - Location \ Type
  // PACK \ PLDT - Location \ Location
  // PACK \ PLDT - Location \ Radius
  // PACK \ PSDT - Schedule \ *
  // PACK \ PSDT - Schedule \ Month|Day of week
  // PACK \ PSDT - Schedule \ Date
  // PACK \ PSDT - Schedule \ Time
  // PACK \ PSDT - Schedule \ Duration
  // PACK \ PTDT - Target \ *
  // PACK \ PTDT - Target \ Type
  // PACK \ PTDT - Target \ Target ==> formid
  // PACK \ PTDT - Target \ Count ==> int
  // QUST \ DATA - General \ Priority ==> int
  if (Pos('QUST \ DATA - General \ Priority', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  // QUST \ Stages \ *
  // QUST \ Stages \ Stage \ INDX - ...
  if (Pos('Stage \ INDX - Stage index', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  // QUST \ Stages \ Log Entries \ Log Entry \ *
  // QUST \ Stages \ Log Entries \ Log Entry \ QSDT - Stage Flags
  // QUST \ Stages \ Log Entries \ Log Entry \ CNAM - Log Entry ==> text
  // QUST \ Stages \ Log Entries \ Log Entry \ Result Script \ *
  // QUST \ Targets \ Target \ *
  // QUST \ Targets \ Target \ QSTA - Target \ *
  // QUST \ Targets \ Target \ QSTA - Target \ Target ==> formid
  // QUST \ Targets \ Target \ Conditions \ CTDA - Condition \ *
  // RACE \ DATA - DATA \ Skill Boosts \ Skill Boost \ *
  // RACE \ DATA - DATA \ Skill Boosts \ Skill Boost \ Skill
  if (Pos('Skill Boost \ Skill', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
  // RACE \ DATA - DATA \ Skill Boosts \ Skill Boost \ Boost
  if (Pos('Skill Boost \ Boost', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  // RACE \ DNAM - Default Hair \ Male|Female ==> formid
  // RACE \ ATTR - Base Attributes \ Male \ *
  // RACE \ ATTR - Base Attributes \ Female \ *
  if (Pos('RACE \ ATTR - Base Attributes \ ', element_path) <> 0) then element_edit_value := IntToStr(native_value);
  // RACE \ Face Data \ NAM0 - Face Data Marker
  // RACE \ Face Data \ Parts \ *
  // RACE \ Face Data \ Parts \ Part \ INDX - ...
  if (Pos(' \ Face Data \ Parts \ Part \ INDX - Index', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
  // RACE \ Face Data \ NAM1 - Body Data Marker
  // RACE \ Male Body Data \ Parts \ *
  // RACE \ Female Body Data \ Parts \ *
  if (Pos(' Body Data \ Parts \ Part \ INDX - Index', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
  // RACE \ HNAM - Hairs \ Hair ==> formid
  // RACE \ ENAM - Eyes \ Eye ==> formid
  // REGN \ Region Areas \ Region Area \ *
  // REGN \ Region Areas \ Region Area \ RPLI - ...
  // REGN \ Region Areas \ Region Area \ RPLD - ...
  // REGN \ Region Data Entries \ Region Data Entry \ *
  // REGN \ Region Data Entries \ Region Data Entry \ RDAT - Data Header \ *
  // REGN \ Region Data Entries \ Region Data Entry \ RDAT - Data Header \ Type
  // REGN \ Region Data Entries \ Region Data Entry \ RDAT - Data Header \ Priority
  // REGN \ Region Data Entries \ Region Data Entry \ RDMD - Music Type
  // REGN \ Region Data Entries \ Region Data Entry \ RDSD - Sounds
  // SOUN \ SNDX - Sound Data \ *
  // SOUN \ SNDX - Sound Data \ Minimum...|Maximum...|Freq..
  // SOUN \ SNDX - Sound Data \ Static Atten...
  // SOUN \ SNDX - Sound Data \ Stop time|Start time
  // SPEL \ SPIT - SPIT \ *
  // SPEL \ SPIT - SPIT \ Type
  // SPEL \ SPIT - SPIT \ Cost
  // SPEL \ SPIT - SPIT \ Level
  // TREE \ CNAM - Tree Data \ Shadow Radius
  // WEAP \ DATA - DATA \ Type
  // WTHR \ NAM0 - Colors by Types/Times \ *
  // WTHR \ NAM0 - Colors by Types/Times \ Type #*** \ *
  // WTHR \ NAM0 - Colors by Types/Times \ Type #*** \ Time #*** \ *
  // WTHR \ NAM0 - Colors by Types/Times \ Type #*** \ Time #*** \ Red|Green|Blue
  // WTHR \ DATA - DATA \ *
  // WTHR \ DATA - DATA \ Wind Speed|Cloud Speed *|Trans Delta|Sun Glare|...
  // WTHR \ Sounds \ SNAM - Sound \ *
  // WTHR \ Sounds \ SNAM - Sound \ Sound ==> formid
  // WTHR \ Sounds \ SNAM - Sound \ Type

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
    json_output[stringlist_length-1] := json_output[stringlist_length-1] + '[';
  end
  else begin
//    json_output.append(prefix + '{');
    stringlist_length := json_output.Count;
    json_output[stringlist_length-1] := json_output[stringlist_length-1] + '{';
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
//    element_edit_value := '"' + GetEditValue(element) + '"';
    element_edit_value := '';
    native_value := GetNativeValue(element);
    native_type := VarType(native_value);

    type_string := '';
    // DEBUGGING
    type_string := '[' + IntToStr(element_type) + ']';
//    AddMessage('DEBUG: VarType=' + VarToStr(VarType(native_value)));
//    AddMessage('DEBUG: element_path=' + element_path + ', element_type=' + IntToStr(element_type));
//  if ( (element_type = etValue) or (element_type = etFlag) or (element_type = etSubRecord)) then
    if (child_count = 0) then
    begin

      if ( (Pos('Unused', element_path) = 0) And (Pos('Unknown', element_path) = 0) ) then
      begin

        element_edit_value := FormatNativeValue(native_value, element_edit_value);

        // Record Header: Signature, Data Size, Record Flags, FormID, Version Control Info
        if (Pos(' \ Record Header \ Data Size', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // * \ Model \ *,
        // * \ BMDT - BMDT \ *

        if ( (Pos('CELL', element_path) <> 0) Or (Pos('PGRD', element_path) <> 0) Or (Pos('LAND', element_path) <> 0)
          Or (Pos('REFR', element_path) <> 0) Or (Pos('ACHR', element_path) <> 0) Or (Pos('ACRE', element_path) <> 0) ) then
        begin
          element_edit_value := ProcessCellRecords(element_path, native_value, element_edit_value)
        end
        else
        begin
          element_edit_value := ProcessNonCellRecords(element, element_path, native_value, element_edit_value)
        end;

        element_edit_value := ReplaceEmptyFlagsString(element_path, native_value, element_edit_value);
        if ((element_type = etArray) Or (element_type = etSubRecordArray)) then element_edit_value := '[]';

      end;

      json_output.append(prefix + prefix2 + type_string + '"' + element_name + '": ' + element_edit_value + postfix2);
    end
    // if child_count <> 0
    else
    begin

      if ((parent_type = etArray) Or (parent_type = etSubRecordArray)) then
      begin
        json_output.append(prefix + prefix2);
      end
      else
      begin
        json_output.append(prefix + prefix2 + type_string + '"' + element_name + '": ');
      end;
      ProcessSubRecord(element, prefix + prefix2, postfix2);
    end;

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
//    element_edit_value := '"' + GetEditValue(element) + '"';
    element_edit_value := '';
    native_value := GetNativeValue(element);
    native_type := VarType(native_value);

    type_string := '';
    // DEBUGGING
  type_string := '[' + IntToStr(element_type) + ']';
//    AddMessage('DEBUG: VarType=' + VarToStr(VarType(native_value)));
//    AddMessage('DEBUG: element_path=' + element_path + ', element_type=' + IntToStr(element_type));
//  if ( (element_type = etValue) or (element_type = etFlag) or (element_type = etSubRecord)) then
    if (child_count = 0) then
    begin

      if ( (Pos('Unused', element_path) = 0) And (Pos('Unknown', element_path) = 0) ) then
      begin

        element_edit_value := FormatNativeValue(native_value, element_edit_value);

        // GENERAL
        // * \ EDID - Editor ID, * \ FULL - Name, * \ SCRI - Script
        // * \ ENAM - Enchantment, * \ ANAM - Enchantment Points
        // BOOK \ DESC - Description
        if (Pos(' \ SCRI - Script', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
        if (Pos(' \ ENAM - Enchantment', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
        if (Pos(' \ ANAM - Enchantment Points', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // * \ DATA - IDLE animation
        if (Pos(' \ DATA - IDLE animation', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
        // * \ XCMT - Music (CELL)
        if (Pos(' \ XCMT - Music', element_path) <> 0) then element_edit_value := '"' + GetEditValue(element) + ':' + IntToStr(native_value) + '"';
        // * \ Name - Base (ACHR, REFR,)
        if (Pos(' \ NAME - Base', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
        // PGRD \ Data - Point Count
        if (Pos(' \ DATA - Point Count', element_path) <> 0) then element_edit_value := IntToStr(native_value);
        // * \ SNAM - Open sound (CONT,DOOR)
        if (Pos(' \ SNAM - Open sound', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
        // * \ QNAM - Close sound (CONT,DOOR)
        if (Pos(' \ QNAM - Close sound', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
        // CREA \ RNAM - Attack reach ==> int
        // TODO: ==> verify
        // CREA \ ZNAM - Combat Style ==> formid
        if (Pos(' \ ZNAM - Combat Style', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
        // CREA \ CSCR - Inherits Sounds from ==> formid
        if (Pos(' \ CSCR - Inherits Sounds from', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
        // INFO \ QSTI - Quest ==> formid
        if (Pos(' \ QSTI - Quest', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
        // INFO \ PNAM - Previous Info ==> formid
        // DOOR \ FNAM - Flags
        // FLOR \ PFIG - Ingredient ==> formid
        // FURN \ MNAM - Marker Flags ==> bytes
        // GLOB\ FNAM - Type
        // IDLE \ ANAM - Animation Group Section
        // LTEX \ SNAM - Texture Specular Exponent
        // * \ LVLD - Chance none (LVLC,LVLI)
        // TODO: ==> verify
        // NPC_ \ RNAM - Race
        if (Pos(' \ RNAM - Race', element_path) <> 0) then element_edit_value := GetFormIDLabel(native_value);
        // NPC_ \ CNAM - Class
        // RACE \ CNAM - Default Hair Color ==> int
        // REGN \ WNAM - Worldspace ==> formid
        // SLGM \ SOUL - Contained Soul
        // SLGM \ SLGM - Maximum Capacity

        element_edit_value := ReplaceEmptyFlagsString(element_path, native_value, element_edit_value);
        if ((element_type = etArray) Or (element_type = etSubRecordArray)) then element_edit_value := '[]';

      end;

      json_output.append(prefix + prefix2 + type_string + '"' + element_path + '": ' + element_edit_value + postfix2);
    end
    // if child_count <> 0
    else
    begin
      json_output.append(prefix + prefix2 + type_string + '"' + element_path + '": ');
      ProcessSubRecord(element, prefix + prefix2, postfix2);
    end;

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

  if not Assigned(target_mod_file) then target_mod_file := GetFile(e);

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
  ForceDirectories(PROGRAMPATH + '\' + element_path);
  json_output.SaveToFile(element_path + element_filename);
  json_output.Clear;
//  json_output.Free;

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
