unit ApplyUniqueOrbitData;

// All values are derived from Major Axis, if no value is set or the value is
// Below 300,000 the script will default to 300,000
// The MIN_MAJOR_AXIS can be lowered, but the CK might error.

var
  PlanetID: Integer;
  GravityWell, TargetCKMaxOrbit: Double;

// Random float generator function
function RandomFloat(min, max: Double): Double;
begin
  Result := min + (Random(10000) / 10000) * (max - min);  // simulate precision for floats
end;

// Function to calculate the Habitable Zone (HZ) based on mass and radius
function CalculateHZ(e: IInterface; Mass, Radius: Double): Double;
var
  innerHZ, outerHZ: Double;
begin
  innerHZ := 0.75 * (Radius / 149597870.7);  // 149597870.7 km is 1 AU
  outerHZ := 1.5 * (Radius / 149597870.7);

  Result := innerHZ;
  SetEditValue(ElementByPath(e, 'HNAM - Unknown\Inner HZ'), FloatToStr(innerHZ));
  SetEditValue(ElementByPath(e, 'HNAM - Unknown\Outer HZ'), FloatToStr(outerHZ));
end;

function Process(e: IInterface): integer;
var
  Body, OrbitalData, MassElement, RadiusElement: IInterface;
  MajorAxis, Eccentricity, MinorAxis, Aphelion, Perihelion, MeanOrbit, AxialTilt: Double;
  Mass, Radius, MIN_MAJOR_AXIS: Double;
  RotationalVelocity: Double;
begin
  if Signature(e) <> 'PNDT' then exit;

  Body := ElementByPath(e, 'Body');
  if not Assigned(Body) then begin
    AddMessage('ERROR: Could not find Body section for ' + Name(e));
    exit;
  end;

  OrbitalData := ElementByPath(Body, 'ENAM - Orbital Data');
  if not Assigned(OrbitalData) then begin
    AddMessage('ERROR: Could not find Orbital Data for ' + Name(e));
    exit;
  end;

  MassElement := ElementByPath(Body, 'FNAM - Orbited Data\Mass (in Earth Masses)');
  RadiusElement := ElementByPath(Body, 'FNAM - Orbited Data\Radius in km');
  if not Assigned(MassElement) or not Assigned(RadiusElement) then begin
    AddMessage('ERROR: Could not find Mass or Radius for ' + Name(e));
    exit;
  end;

  Mass := StrToFloat(GetEditValue(MassElement));
  Radius := StrToFloat(GetEditValue(RadiusElement));

  // Pass 'e' to CalculateHZ
  CalculateHZ(e, Mass, Radius);

  RotationalVelocity := RandomFloat(0, 7);
  SetEditValue(ElementByPath(OrbitalData, 'Rotational Velocity'), FloatToStr(RotationalVelocity));

  MajorAxis := StrToFloat(GetEditValue(ElementByPath(OrbitalData, 'Major Axis')));
  MIN_MAJOR_AXIS := 300000.0;

  if MajorAxis < MIN_MAJOR_AXIS then begin
    AddMessage('### Warning: Major Axis was below the CK minimum. Adjusted to 250,000 km. ###');
    MajorAxis := MIN_MAJOR_AXIS;
    SetEditValue(ElementByPath(OrbitalData, 'Major Axis'), FloatToStr(MajorAxis));
  end;

  Eccentricity := RandomFloat(0.001, 0.5);
  MinorAxis := MajorAxis * Sqrt(1 - Eccentricity * Eccentricity); 
    
  // Set CK-compliant Gravity Well to ensure CK Max Orbit > Min Orbit
  TargetCKMaxOrbit := 5500; // You can change this as needed
  GravityWell := (TargetCKMaxOrbit / 338) * MajorAxis;
  SetEditValue(ElementByPath(Body, 'FNAM - Orbited Data\Gravity Well'), FloatToStr(GravityWell));
  
  Aphelion := MajorAxis * (1 + Eccentricity);
  Perihelion := MajorAxis * (1 - Eccentricity);
  AxialTilt := RandomFloat(0.001, 60);
  MeanOrbit := RandomFloat(Perihelion + (Aphelion - Perihelion) * 0.25,
                         Perihelion + (Aphelion - Perihelion) * 0.75);

  SetEditValue(ElementByPath(OrbitalData, 'Eccentricity'), FloatToStr(Eccentricity));
  SetEditValue(ElementByPath(OrbitalData, 'Minor Axis'), FloatToStr(MinorAxis));
  SetEditValue(ElementByPath(OrbitalData, 'Aphelion'), FloatToStr(Aphelion));
  SetEditValue(ElementByPath(OrbitalData, 'Axial Tilt'), FloatToStr(AxialTilt));
  SetEditValue(ElementByPath(OrbitalData, 'Mean Orbit'), FloatToStr(MeanOrbit));

  SetEditValue(ElementByPath(Body, 'HNAM - Unknown\Perihelion'), FloatToStr(Perihelion));

  AddMessage('Updated ' + Name(e) + ' with new orbit data:');
  AddMessage('Major Axis: ' + FloatToStr(MajorAxis) + ', Eccentricity: ' + FloatToStr(Eccentricity) +
             ', Minor Axis: ' + FloatToStr(MinorAxis) + ', Aphelion: ' + FloatToStr(Aphelion) +
             ', Perihelion: ' + FloatToStr(Perihelion) + ', Mean Orbit: ' + FloatToStr(MeanOrbit) +
             ', Axial Tilt: ' + FloatToStr(AxialTilt) + ', Inner HZ: ' + FloatToStr(Mass) +
             ', Outer HZ: ' + FloatToStr(Radius) + ', Rotational Velocity: ' + FloatToStr(RotationalVelocity));

  Result := 0;
end;

function Initialize: Integer;
begin
  PlanetID := 50;
  Result := 0;
end;

end.
