% GETDBASE  On first call for a session, all float details are loaded from
%   the master database (massaging some fields in the process) into global 
%   variables.  If 'fnum' provided, extracts record for that float. 
%
% INPUT: fnum - WMO ID of float for which DB record required (not required 
%               if simply want to load global DB variables.)
%               fnum= -1  will force REloading of the database.
%
% OUTPUT: dbdat - structure of details for the specified float (empty if
%                 no fnum specified)
%
% File INPUT:  Reads  spreadsheet/argomaster.csv  which is a csv dump of
%              sheet 1 of argomaster.xls
%
% GLOBALS: If not already loaded this session, these global variables are
%          created:
%   THE_ARGO_FLOAT_DB - struct array of float details for every float
%   ARGO_ID_CROSSREF  - (nfloat X 3) array, rows comprising 
%         1) WMO ID    2) ARGOS ID   3) deployment num
%
% TO TEST:   for fn = [list of all float numbers...]
%                dbdat = getdbase(fn);
%            end
%
% Warnings:  Reports if 'Manufacturer' field is not as expected, or if
%   'endrow' flag is not in expected column. Both may arise if spreadsheet
%   is incomplete or if structure has been altered. 
%
% SEE ALSO:  idcrossref.m   getcaldbase.m
%
% Author:  Jeff Dunn CMAR/BoM Aug 2006
%
% USAGE: dbdat = getdbase(fnum);

function dbdat = getdbase(fnum)

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

if nargin<1 || isempty(fnum)
   fnum = 0;
elseif fnum==-1
   % this forces us to reload the database (might be useful one day)
   THE_ARGO_FLOAT_DB = [];
end

if isempty(THE_ARGO_FLOAT_DB)
   % Must be first call - so construct the database!
   % Give the new database struct array a nice short name "T" while we are 
   % building it, then store it in the nice long name as befits a global variable.

   if isempty(ARGO_SYS_PARAM)
      set_argo_sys_params;
   end
   if ispc
   fnm = [ARGO_SYS_PARAM.root_dir 'spreadsheet\argomaster.csv'];
   else
   fnm = [ARGO_SYS_PARAM.root_dir 'spreadsheet/argomaster.csv'];
   end
   if ~exist(fnm,'file')
      error(['Cannot find database file ' fnm]);
   end
      
   fid = fopen(fnm,'r');
   %35 columns. Edit here if we need to add/remove columns
   tmpdb = textscan(fid,repmat('%s',1,36),'delimiter',',','headerlines',2);  
   fclose(fid);

   % stick with this setup, probably more efficient ways of doing it...
   for ientry = 1:length(tmpdb{1})
       for ncol = 1:length(tmpdb)
           fld = tmpdb{ncol}{ientry};
           switch ncol
               case 1
                   % Just the start of line marker
               case 2
                   T(ientry).status = fld;
               case 3
                   tmp=fld;
                   T(ientry).launchdate = tmp;
               case 4
                   T(ientry).launch_lat = str2num(fld);
               case 5
                   T(ientry).launch_lon = str2num(fld);
               case 6
                   T(ientry).argos_id = str2num(fld);
               case 7
                   T(ientry).wmo_id = str2num(fld);
               case 8
                   T(ientry).maker_id =  str2num(fld);
               case 9
                   T(ientry).argos_hex_id = fld;
               case 10
                   T(ientry).deploy_num = str2num(fld);
               case 11
                   T(ientry).owner = fld;
               case 15
                   T(ientry).PI = fld;
               case 16
                   T(ientry).wmo_inst_type = fld;
               case 17
                   T(ientry).ctd_sensor_type = fld;
                   T(ientry).RBR = ~isempty(strfind(lower(fld),'rbr'));
               case 18
                   T(ientry).sbe_snum = str2num(fld);
               case 19
                   if(isempty(fld))
                       T(ientry).boardtype = [];
                   else
                       T(ientry).boardtype = fld;
                   end
               case 20
                   dt=strfind(fld,'-');
                   if isempty(dt);dt=0;end
                   T(ientry).controlboardnum = str2num(fld(dt+1:end));
                   T(ientry).controlboardnumstring = fld;
               case 21
                   T(ientry).oxysens_snum = str2num(fld);
               case 22
                   T(ientry).psens_snum = str2num(fld);
               case 23
                   T(ientry).reprate = str2num(fld);
               case 24
                   T(ientry).parktime = str2num(fld);
               case 25
                   T(ientry).asctime = str2num(fld);
               case 26
                   T(ientry).surftime = str2num(fld);
               case 27
                   T(ientry).parkpres = str2num(fld);
               case 28
                   T(ientry).uptime = str2num(fld);
               case 29
                   T(ientry).profpres = str2num(fld);
               case 30
                   T(ientry).launch_platform = fld;
               case 31
                   T(ientry).np0 = str2num(fld);
               case 32
                   fld = lower(fld);
                   if ~isempty(strfind(fld,'webb'))
                       T(ientry).maker = 1;
                   elseif ~isempty(strfind(lower(fld),'provor'))
                       T(ientry).maker = 2;
                   elseif ~isempty(strfind(fld,'seabird'))
                       T(ientry).maker = 4;
                   elseif ~isempty(strfind(fld,'soloii'))
                       T(ientry).maker = 5;
                   elseif ~isempty(strfind(fld,'solo'))
                       T(ientry).maker = 3;
                   elseif ~isempty(strfind(fld,'nke'))
                       T(ientry).maker = 6;
                   elseif ~isempty(strfind(fld,'mrv'))
                       T(ientry).maker = 5;
                   else
                       T(ientry).maker = 0;
                       if isempty(fld)
                           disp(['GETDBASE: Error - empty Manufacturer field, row' ...
                               num2str(ientry)]);
                       else
                           disp(['GETDBASE: Error - Manufacturer=' fld ...
                               ', in row ' num2str(ientry)]);
                       end
                   end
               case 33
                   T(ientry).subtype = str2num(fld);
               case 34
                   fld = lower(fld);
                   T(ientry).ice = ~isempty(strfind(fld,'i'));
                   T(ientry).oxy = ~isempty(strfind(fld,'o'));
                   T(ientry).tmiss = ~isempty(strfind(fld,'t'));
                   T(ientry).flbb = ~isempty(strfind(fld,'f'));
                   T(ientry).em = ~isempty(strfind(fld,'e'));
                   T(ientry).suna = ~isempty(strfind(fld,'s'));
                   T(ientry).flbb2 = ~isempty(strfind(fld,'f2'));  %flbb with chl and 2 BB sensors
                   T(ientry).eco = ~isempty(strfind(fld,'x'));  %eco puck with three BB sensors
                   T(ientry).irr = ~isempty(strfind(fld,'r'));  %upward and downward irradiance sensors
                   T(ientry).irr2 = ~isempty(strfind(fld,'r2'));  %downward irradiance sensors with PAR
                   T(ientry).pH = ~isempty(strfind(fld,'p'));  %pH sensor
               case 35
                   fld = upper(fld);
                   T(ientry).pressure_sensor = fld;
               case 36
                   T(ientry).iridium = ~isempty(strfind(lower(fld),'iridium'));                   
               otherwise
                   % we don't need these other fields (for now)
                   
           end    % end of 'switch'
       end     % end of 'ientry>0  (ie have got past headers, started float rows)
   end
   
   
   % Create a WMO ID lookup table (and an ID cross-ref table)

   ARGO_ID_CROSSREF = zeros(ientry,4);
   for ii = 1:ientry
      if ~isempty(T(ii).wmo_id)
	 ARGO_ID_CROSSREF(ii,1) = T(ii).wmo_id;
      end
      if ~isempty(T(ii).argos_id)
	 ARGO_ID_CROSSREF(ii,2) = T(ii).argos_id;
      end
      if ~isempty(T(ii).deploy_num)
	 ARGO_ID_CROSSREF(ii,3) = T(ii).deploy_num;
      end
      if ~isempty(T(ii).status)
	 % 0="dead" float, 1=not a "dead" float
	 ARGO_ID_CROSSREF(ii,4) = isempty(strfind(T(ii).status,'dead')) & isempty(strfind(T(ii).status,'exhausted'));
      end   
      if ~isempty(T(ii).status)
	 % 0="dead" float, 1="live" float (suspects are eliminated)
	 ARGO_ID_CROSSREF(ii,6) = ((isempty(strfind(T(ii).status,'dead')) & isempty(strfind(T(ii).status,'exhausted')))...
         && isempty(strfind(T(ii).status,'suspect')));
      end         
      if ~isempty(T(ii).maker_id)
	 ARGO_ID_CROSSREF(ii,5) = T(ii).maker_id;
      end
   end
   
   THE_ARGO_FLOAT_DB = T;
end
      

if fnum>0
   ii = find(ARGO_ID_CROSSREF(:,1)==fnum);
   if isempty(ii)
      disp(['Error - cannot find float ' num2str(fnum) ' in the database']);
      dbdat = [];
      return
   end
   dbdat = THE_ARGO_FLOAT_DB(ii);
else
   dbdat = [];
end

return

%----------------------------------------------------------------------------
