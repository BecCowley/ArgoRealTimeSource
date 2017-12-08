%  function [latarr,lonarr]=interpolate_locations(dbdat)
%
%  this script takes a float structure and checks to see if locations from
%  previous profiles are missing. if so, it interpolates from teh current
%  location and previous locations and adds them to the mat structure. It
%  then generates the tesac and netcdf files for the float for delivery to
%  the GDACs and GTS.

function [float,pro]=interpolate_locations(dbdat,float,pro)

global ARGO_SYS_PARAM

latarr=[];
lonarr=[];
needpos=[];

%if this profile has a nan, we can't interp yet. In the case of
%re-processing, we need to esure we don't re-interp accross already guessed
%values. This will be an issue if we are reprocessing just one file with a
%missing position, without the bracketing files.
if isnan(pro.lat)
    return
end

%assign all the data so far:
float(pro.profile_number) = pro;

%get all the nans in lat:
ii = find(cellfun(@any,cellfun(@isnan,{float.lat},'uniformoutput',0))==1);
ij = find(cellfun(@isempty,{float.lat}));
ik = sort([ii,ij]);
if isempty(ik)
    %no missing position info
    return
end

%clear out existing interpolations and re-do.
ii = find(cellfun(@(x) x==8,{float.pos_qc},'Uniformoutput',1)==1);
ij = find(cellfun(@(x) x==9,{float.pos_qc},'Uniformoutput',1)==1);
ik = sort([ii ij]);
for g = 1:length(ik)
    float(ik(g)).lat = NaN;
    float(ik(g)).lon = NaN;
    float(ik(g)).pos_qc = 9;
    float(ik(g)).jday = [];
    float(ik(g)).position_accuracy=' ';
end
%look for different groups of missing postions:
iid = find(diff(ik)>1);
if isempty(iid)
    iid = length(ik);
else
    %more than one group
    iid = [iid,length(ik)];
end

st = 1;
for a = 1:length(iid)
    ii = ik(st:iid(a));
    if ii(1) == 1
        %can't interpolate as the first position is missing. So use launch
        %lat/lon
        startlat=dbdat.launch_lat;
        startlon=dbdat.launch_lon;
        startjday=julian([str2num(dbdat.launchdate(1:4)) str2num(dbdat.launchdate(5:6)) str2num(dbdat.launchdate(7:8)) ...
            str2num(dbdat.launchdate(9:10)) str2num(dbdat.launchdate(11:12)) str2num(dbdat.launchdate(13:14))])
    else
        %use last postion fix
        startlat=float(ii(1)-1).lat(end);
        startlon=float(ii(1)-1).lon(end);
        startjday = float(ii(1)-1).jday_location(end);
    end
    %use first postion fix of this profile
    endlat = float(ii(end)+1).lat(1);
    endlon = float(ii(end)+1).lon(1);
    endjday = float(ii(end)+1).jday_location(1);
    
    %now need to calculate the approximate jdays for missing profiles
    xq = 1:length(ii)+2;
    vql = interp1([xq(1),xq(end)],[startjday,endjday],xq);
    needpos = vql(2:end-1);
    
    if ~isempty(needpos)
        %check for longitude that has gone over the 360 degrees:
        %first unwrap the longitude
        lld = abs(startlon-endlon);
        ld = abs(360-endlon+startlon);
        [~,jj] = min([lld, ld]);%smallest distance
        if jj == 2 % the float passed over the 360 degrees line
            if startlon < endlon %end longitude is bigger
                ll = endlon-360;
                lonarr = interp1([startjday endjday],[startlon ll],needpos);
                ij = lonarr < 0;
                lonarr(ij) = 360+lonarr(ij);
            else
                ll = startlon-360;
                lonarr = interp1([startjday endjday],[ll endlon],needpos);
                ij = lonarr < 0;
                lonarr(ij) = 360+lonarr(ij);
                
            end
        else
            %no cross over
            lonarr = interp1([startjday endjday],[startlon endlon],needpos);
        end
        latarr = interp1([startjday endjday],[startlat endlat],needpos);
        % now regenerate and save mat files:
        
        for g=1:length(ii)
            float(ii(g)).jday = needpos(g);
            float(ii(g)).lat = str2num(sprintf(('%5.3f'),latarr(g)));
            float(ii(g)).lon = str2num(sprintf(('%5.3f'),lonarr(g)));
            float(ii(g)).position_accuracy='8';
            float(ii(g)).pos_qc=8;
        end
        
        fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];
        
        save(fnm,'float','-v6');
        
        % now re-generate netcdf files:
        
        for g=1:length(ii)
            if ~isempty(float(ii(g)).jday) & ~isempty(float(ii(g)).wmo_id)
                argoprofile_nc(dbdat,float(ii(g)));
                write_tesac(dbdat,float(ii(g)));
                web_profile_plot(float(ii(g)),dbdat);
            end
        end
        web_float_summary(float,dbdat,1);
        locationplots(float);
        % done!
    end
    st = iid(a)+1;
end

%now assign the interpolated values back to pro.
pro = float(pro.profile_number);

return
