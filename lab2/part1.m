%% MECH 6970 Lab 2, Part 1
% Robert Cofield, et al.
% 
% due 2013-09-30
% 
% *Run this file in its directory*
%    - that's unrobust, I know, but it's late...
%
% _Prerequisites_
%   - `mydate` package (fileexchange)
%   - `goGPS` (gogps-project.org) - I did add with subfolders
%   - `rgc_matlab` (github.com/ozymandium/rgc_matlab)
%         - just need to add top level to path
% 
genutil.ccc

%% Configurating
% 

% UTC Time datevec from first GPZDA message of second data file (*.ubx)
dtvec = [2013,09,10,17,37,34]; % here's hard-coding. oh well.
% LLA position of the user (for skyplot) - got it from GPGLL message
% 3236.36035,N,08529.22476,W
user_lla = [coordutil.dms2d(32,36.36035,0),...
            -coordutil.dms2d(85,29.22476,0),...
            250]; % that one's just a guess.

%% Time Figuring Outing
% 

yrstr = num2str(dtvec(1));
doy = timeutil.datevec2doy(dtvec); % day of year, from rgc_matlab
% with this we can get CDDIS ephems, but want precise ephem
% get gps week and seconds into week
[wk,sec] = mydategps(mydatenum(dtvec)); % you'll need the mydate package installed
% day of week (0=Sun, 6=Sat)
dow = weekday(datestr(dtvec))-1;

%% CDDIS Ephemeris Getting & Parsing
% 

% find the internet address for CDDIS ephem
% cddis = ftp('cddis.gsfc.nasa.gov'); % ftp object for the server
% filename
cddis_addr = ['pub/gps/data/daily/', yrstr, '/brdc/'];
cddis_fname = ['brdc' sprintf('%3.3d',doy) '0.' yrstr(3:4) 'n.Z'];
mkdir(['..' filesep 'data' filesep 'stmp']);
% the paths here probably won't work on Windows .. Meh.
system(['python ..' filesep 'data' filesep 'download_cddis_data.py ' cddis_addr cddis_fname ' ..' filesep 'data' filesep 'tmp/']);
cddis_fname =  cddis_fname(1:end-2); % take off the .Z
[ephem_full,~] = RINEX_get_nav(['..' filesep 'data' filesep 'tmp' filesep cddis_fname]);
% At this point you now have a 33x416 matrix of ephemeris datas. yippee.

%% JPL Precise Ephemeris
% -- Unfinished.

% % find the internet address for JPL precise ephem
% jpl_addr = ['http://igscb.jpl.nasa.gov/igscb/product/', num2str(wk), '/']; % folder
% jpl_addr = [jpl_addr, 'igr', num2str(wk*10+dow), '.sp3.Z']; % filename
% % urlwrite(jpl_addr, 'precise_ephem_jpl.rinex');

%% SV Position Calculation
% assume that week # does not change during this data
gps.constants

[ephem,svprn,t_oc] = gps.ephem_gogps2gavlab(ephem_full); % rearrange the rows
svpos = zeros(3,32,length(svprn)/32);
svpos_ae = svpos(1:2,:,:); % azimuth, elevation
prn_data_cnt = ones(1,32); % which epoch for each SV we are on
% need a rough transit time estimation
range_est = 20e6;
t_transit_est = range_est/c;

% !? It may end up having different numbers of epochs for some SV's than
% others??
for k = 1:length(svprn)
  prn = svprn(k);
  
  % calculate ECEF position for each sv at each epoch
  t_tx = t_oc(k);
  [pos, clk_corr] = gps.calc_sv_pos(ephem, t_tx, t_transit_est);
  svpos(:,prn,prn_data_cnt(prn)) = pos;
  
  % find spherical coordinates for each satellite at each epoch
  [sv_lat,sv_lon,sv_alt] = coordutil.wgsxyz2lla(pos);  %!!! It gets stuck here b/c the inputs are dead wrong.
  % SV pos relative to user in ENU
  dp_enu = coordutil.wgslla2enu(sv_lat,sv_lon,sv_alt, user_lla(1),user_lla(2),user_lla(3));
  [a,e,r] = cart2sph(dp_enu(1),dp_enu(2),dp_enu(3)); 
  svpos_ae(:,prn,prn_data_cnt(prn)) = [a;e];
  
  prn_data_cnt(prn) = prn_data_cnt(prn)+1;
end




























