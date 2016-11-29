% VALIDATE:  Validate model outputs against historical hydrographic casts
%
% INPUT: 
%  fsz    fontsize for plots [default 16 points]
%  tdmax  max allowed time gap between cast and model timestep (default 10 days)
%  rmax   max allowed distance between cast and model grid point (def .5 degrees)
%  just1  1=if neighbouring model profiles have different "data" depths, use
%         just nearest profile rather than interpolating, to preserve shape.
%         (default 1)
%
%  Copyright     Jeff Dunn, CSIRO Marine Research Feb 2003
% 
% This program has a GUI.  See validate_doc.txt for more details
%
% Note: Casts are interpolated to model depths for comparison
%
% USAGE:  validate(fsz,tdmax,rmax,just1)

function validate(a1,a2,a3,a4)

% $Id: validate.m,v 1.3 2003/03/17 01:42:31 dun216 Exp dun216 $
% Matlab version 5.2

global alert defafs deftfs Vdeph Vlevh
global tdmax rmax just1

fsz = 16; tdmax = 10; rmax = .5; just1 = 1;

if nargin>0 & ~isempty(a1)
   fsz = a1;
end
if nargin>1 & ~isempty(a2)
   tdmax = a2;
end
if nargin>2 & ~isempty(a3)
   rmax = a3;
end
if nargin>3 & ~isempty(a4)
   just1 = a4;
end


ncquiet

vers = version;
nver = str2num(vers(1)) + str2num(vers(2))/10;
if nver<6.5
   error('Sorry - VALIDATE requires Matlab version 6.5')
end

a = figure('Units','points', ...
      'Color',[0.7 0.7 0.7], ...
      'MenuBar','none', ...
      'PaperType','a4letter', ...
      'Name','GUI for model validation', ... 
      'NumberTitle','off', ...
      'Position',[0 360 400 450]);

%- Static text

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[0.7 0.7 0.7], ...
      'FontSize',12, ...
      'FontWeight','demi', ...
      'ForegroundColor',[0 0 1], ...
      'Position',[80 425 240 23], ...
      'String','Model-Observation Validation Menu', ...
      'Style','text');

%- File names and paths

b = uicontrol('Parent',a, 'Units','points', ...
      'BackgroundColor',[1 0 0], ...
      'FontSize',10, ...
      'Callback','val_util(''get_file'')', ...
      'Position',[5 360 60 45], ...
      'String','Get file', ...
      'Tag','get_file');

b = uicontrol('Parent',a, 'Units','points', ...
      'BackgroundColor',[.8 .8 .8], ...
      'FontSize',10, ...
      'Position',[70 350 320 80], ...
      'Tag','filenames', ...
      'Style','listbox', ...
      'Value',1);


% Property selection

mcol = [.8 .6 .5];
b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',mcol, ...
      'Style','text', ...
      'Position',[5 195 390 150], ...
      'String','');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',mcol, ...
      'Style','text', ...
      'FontSize',12, 'Fontweight','demi', ...
      'Position',[10 320 85 20], ...
      'String','Property');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[0.8 0.8 0.8], ...
      'Callback','val_util(''set_property'')', ...
      'FontSize',12, ...
      'Style','listbox', ...
      'Position',[10 200 85 120], ...
      'Tag','set_prop', ...
      'Value',1);


%- Region selection controls

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',mcol, ...
      'Style','text', ...
      'FontSize',12, 'Fontweight','demi', ...
      'Position',[115 320 110 20], ...
      'String','Region Selection');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[0.7 0.7 0.7], ...
      'Callback','val_util(''reset_reg'')', ...
      'FontSize',10, ...
      'Position',[120 300 100 20], ...
      'String','Entire domain');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[0.7 0.7 0.7], ...
      'Callback','val_util(''select_reg'')', ...
      'FontSize',10, ...
      'Position',[120 275 100 20], ...
      'String','Set on the map');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',mcol, ...
      'FontSize',10, ...
      'Position',[120 250 100 20], ...
      'String','Manual Selection', ...
      'Style','text');
b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',mcol, ...
      'FontSize',10, ...
      'Position',[100 230 30 20], ...
      'String','W E', ...
      'Style','text');
b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[1 1 1], ...
      'Callback','val_util(''ew_region'')', ...
      'Position',[130 235 110 20], ...
      'Style','edit', ...
      'Tag','ew_region');
b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',mcol, ...
      'FontSize',10, ...
      'Position',[100 205 30 20], ...
      'String','S N', ...
      'Style','text');
b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[1 1 1], ...
      'Callback','val_util(''ns_region'')', ...
      'Position',[130 210 110 20], ...
      'Style','edit', ...
      'Tag','ns_region');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',mcol, ...
      'FontSize',10, ...
      'Position',[230 305 70 17], ...
      'String','Start Date', ...
      'Style','text');
b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[1 1 1], ...
      'Callback','val_util(''st_date'')', ...
      'Position',[300 305 90 20], ...
      'Style','edit', ...
      'Tag','st_date');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',mcol, ...
      'FontSize',10, ...
      'Position',[230 280 70 17], ...
      'String','End Date', ...
      'Style','text');
b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[1 1 1], ...
      'Callback','val_util(''end_date'')', ...
      'Position',[300 280 90 20], ...
      'Style','edit', ...
      'Tag','end_date');


b = uicontrol('Parent',a, 'Units','points', ...
      'BackgroundColor',[.7 .7 .7], ...
      'Callback','val_util(''load_reg'')', ...
      'FontSize',12, ...
      'Position',[280 245 100 20], ...
      'String','Load region', ...
      'Tag','load_region');

b = uicontrol('Parent',a, 'Units','points', ...
      'BackgroundColor',[0.7 0.7 0.7], ...
      'Callback','val_util(''save_to_file'')', ...
      'FontSize',10, ...
      'Position',[280 215 100 20], ...
      'String','Save casts to file');

% Alert panel

alert = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[1 1 1], ...
      'ForegroundColor',[1 0 0], ...
      'FontSize',12, ...
      'Position',[10 155 380 30], ...
      'Style','text', ...
      'String','', ...
      'Tag','alert_panel');


% Plot axis and printing controls

bgcol = [0.7 0.8 1];
b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',bgcol, ...
      'FontSize',12, 'Fontweight','demi', ...
      'Style','text', ...
      'Position',[5 5 390 140], ...
      'String','Plot Controls');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[0.7 0.7 0.7], ...
      'Callback','val_util(''set_curfig'')', ...
      'FontSize',12, ...
      'Style','listbox', ...
      'Position',[10 10 90 125], ...
      'Tag','plot_names', ...
      'Value',1);

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',bgcol, ...
      'FontSize',10, ...
      'Position',[150 105 90 20], ...
      'String','Manual setting', ...
      'Style','text');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',bgcol, ...
      'FontSize',12, ...
      'Position',[105 85 40 20], ...
      'String','X axis', ...
      'Style','text');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[.9 .9 .9], ...
      'ForegroundColor',[.9 .1 .1], ...
      'Callback','val_util(''auto_xlim'')', ...
      'Position',[280 90 90 20], ...
      'Style','checkbox', ...
      'Value',1, ...
      'String','Autoscale X', ...
      'Tag','auto_xlim');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[1 1 1], ...
      'Callback','val_util(''fix_xlim'')', ...
      'Position',[145 90 120 20], ...
      'Style','edit', ...
      'Tag','x_lim');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',bgcol, ...
      'FontSize',12, ...
      'Position',[105 60 40 20], ...
      'String','Y axis', ...
      'Style','text');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[.9 .9 .9], ...
      'ForegroundColor',[.9 .1 .1], ...
      'Callback','val_util(''auto_ylim'')', ...
      'Position',[280 65 90 20], ...
      'Style','checkbox', ...
      'Value',1, ...
      'String','Autoscale Y', ...
      'Tag','auto_ylim');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[1 1 1], ...
      'Callback','val_util(''fix_ylim'')', ...
      'Position',[145 65 120 20], ...
      'Style','edit', ...
      'Tag','y_lim');

b = uicontrol('Parent',a, ...
      'Units','points', ...
      'BackgroundColor',[0.7 0.7 0.7], ...
      'Callback','val_util(''print_plot'')', ...
      'FontSize',10, ...
      'Position',[295 15 90 20], ...
      'String','Save plot');

%- Activity controls

b = uicontrol('Parent',a, 'Units','points', ...
      'Callback','val_util(''finish'')', ...
      'FontSize',12, ...
      'Position',[5 425 40 20], ...
      'String','Exit');



%          GUI set up, now set things rolling...

defafs = get(0,'defaultaxesfontsize');
deftfs = get(0,'defaulttextfontsize');
set(0,'defaultaxesfontsize',fsz);
set(0,'defaulttextfontsize',fsz);

spath = which('dep_csl');
if isempty(spath)
   vpth = platform_path('fips','eez_data/software/matlab/');
   disp(['Adding path ' vpth ', for functions called by "validate"'])
   eval(['addpath ' vpth ' -end']);
end

val_util('init')

%---------------------------------------------------------------------------
