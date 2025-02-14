%% Simulation Data
simu = simulationClass();               
simu.simMechanicsFile = 'OSWEC_Hydraulic_Crank_PTO.slx';  % Specify Simulink Model File with PTO-Sim                  
simu.startTime = 0;                     
simu.rampTime = 100;                       
simu.endTime=400;                       
simu.dt = 0.01;                         
simu.cicEndTime = 30;
simu.explorer = 'off';                     % Turn SimMechanics Explorer (on/off)

%% Wave Information
%Irregular Waves using PM Spectrum
waves = waveClass('irregular');
waves.height = 2.5;
waves.period = 8;
waves.spectrumType = 'PM';
waves.phaseSeed=1;

%% Body Data
% Flap
body(1) = bodyClass('../hydroData/oswec.h5');   
body(1).geometryFile = '../geometry/flap.stl';    
body(1).mass = 127000;                         
body(1).inertia = [1.85e6 1.85e6 1.85e6]; 
body(1).linearDamping(5,5) = 1*10^7;    % Specify damping on body 1 in pich

% Base
body(2) = bodyClass('../hydroData/oswec.h5');   
body(2).geometryFile = '../geometry/base.stl';    
body(2).mass = 'fixed';                        

%% PTO and Constraint Parameters
% Fixed Constraint
constraint(1)= constraintClass('Constraint1');  
constraint(1).location = [0 0 -10];                  

% Rotational PTO
pto(1) = ptoClass('PTO1');                          % Initialize ptoClass for PTO1
pto(1).stiffness = 0;                               % PTO Stiffness Coeff [Nm/rad]
pto(1).damping = 0;                                 % PTO Damping Coeff [Nsm/rad]
pto(1).location = [0 0 -8.9];                       % PTO Location [m]

%% PTO-Sim blocks definition

%Linear crank
ptoSim(1) = ptoSimClass('PTOSim1');
ptoSim(1).number  = 1;
ptoSim(1).type = 6;
ptoSim(1).linearCrank.crank = 3;
ptoSim(1).linearCrank.offset = 1.3;
ptoSim(1).linearCrank.rodLength = 5;

%Hydraulic Cylinder
ptoSim(2) = ptoSimClass('PTOSim2');
ptoSim(2).number  = 2;
ptoSim(2).type = 2;
ptoSim(2).hydPistonCompressible.xi_piston = 35;
ptoSim(2).hydPistonCompressible.Ap_A = 0.0378;
ptoSim(2).hydPistonCompressible.Ap_B = 0.0378;
ptoSim(2).hydPistonCompressible.bulkModulus = 1.86e9;
ptoSim(2).hydPistonCompressible.pistonStroke = 70;
ptoSim(2).hydPistonCompressible.pAi = 1.4e7;
ptoSim(2).hydPistonCompressible.pBi = 1.4e7;

%Rectifying Check Valve
ptoSim(3) = ptoSimClass('PTOSim3');
ptoSim(3).number = 3;
ptoSim(3).type = 4;
ptoSim(3).rectifyingCheckValve.Cd = 0.61;
ptoSim(3).rectifyingCheckValve.Amax = 0.002;
ptoSim(3).rectifyingCheckValve.Amin = 1e-8;
ptoSim(3).rectifyingCheckValve.pMax = 1.5e6;
ptoSim(3).rectifyingCheckValve.pMin = 0;
ptoSim(3).rectifyingCheckValve.rho = 850;
ptoSim(3).rectifyingCheckValve.k1 = 200;
ptoSim(3).rectifyingCheckValve.k2 = ...
    atanh((ptoSim(3).rectifyingCheckValve.Amin-(ptoSim(3).rectifyingCheckValve.Amax-ptoSim(3).rectifyingCheckValve.Amin)/2)*...
    2/(ptoSim(3).rectifyingCheckValve.Amax - ptoSim(3).rectifyingCheckValve.Amin))*...
    1/(ptoSim(3).rectifyingCheckValve.pMin-(ptoSim(3).rectifyingCheckValve.pMax + ptoSim(3).rectifyingCheckValve.pMin)/2);

%High Pressure Hydraulic Accumulator
ptoSim(4) = ptoSimClass('PTOSim4');
ptoSim(4).number  = 4;
ptoSim(4).type = 3;
ptoSim(4).gasHydAccumulator.vI0 = 8.5;
ptoSim(4).gasHydAccumulator.pIprecharge = 2784.7*6894.75;

%Low Pressure Hydraulic Accumulator
ptoSim(5) = ptoSimClass('PTOSim5');
ptoSim(5).number  = 5;
ptoSim(5).type = 3;
ptoSim(5).gasHydAccumulator.vI0 = 8.5;
ptoSim(5).gasHydAccumulator.pIprecharge = 1392.4*6894.75;

%Hydraulic Motor
ptoSim(6) = ptoSimClass('PTOSim6');
ptoSim(6).number  = 6;
ptoSim(6).type = 5;
ptoSim(6).hydraulicMotor.effModel = 2;
ptoSim(6).hydraulicMotor.displacement = 120;
ptoSim(6).hydraulicMotor.effTableShaftSpeed = linspace(0,2500,20);
ptoSim(6).hydraulicMotor.effTableDeltaP = linspace(0,200*1e5,20);
ptoSim(6).hydraulicMotor.effTableVolEff = ones(20,20)*0.9;
ptoSim(6).hydraulicMotor.effTableMechEff = ones(20,20)*0.85;

%Electric generator
ptoSim(7) = ptoSimClass('PTOSim7');
ptoSim(7).number = 7;
ptoSim(7).type = 1;
ptoSim(7).electricGeneratorEC.Ra = 1;
ptoSim(7).electricGeneratorEC.La = 0.1;
ptoSim(7).electricGeneratorEC.Ke = 1.0;
ptoSim(7).electricGeneratorEC.Jem = 2;
ptoSim(7).electricGeneratorEC.currentIni = 0.0;
ptoSim(7).electricGeneratorEC.wShaftIni = 0;

%Control system variables
PTOControl.PG = 0.001;
PTOControl.IG = 0.001;
PTOControl.ShaftSpeedRef = 3000;