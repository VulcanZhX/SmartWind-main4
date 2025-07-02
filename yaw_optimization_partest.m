clc
clear
close all
% load y2_0_8_initial.mat
rng('default')

%% 场群风资源输入设置
% 风向扇区
wind_sectors=8;

%风向划分，正北-东北：0-45度；东北-东：45-90度；东-东南：90-135度；东南-南：135-180；南-西南：180-225度；西南-西：225-270度；西-西北：270-325度；西北-北：325-360度
%1.正北-东北：0-45度
windfarmcluster_wind_direction_N_NE=0:5:45;
windfarmcluster_wind_speed_N_NE=3:1:12;

%2.东北-东：45-90度
windfarmcluster_wind_direction_NE_E=45:5:90;
windfarmcluster_wind_speed_NE_E=3:1:12;


%3.东-东南：90-135度
windfarmcluster_wind_direction_E_SE=90:5:135;
windfarmcluster_wind_speed_E_SE=3:1:10;

%4.东南-南：135-180
windfarmcluster_wind_direction_SE_S=135:5:180;
windfarmcluster_wind_speed_SE_S=3:1:10;

%5.南-西南：180-225度
windfarmcluster_wind_direction_S_SW=180:5:225;
windfarmcluster_wind_speed_S_SW=3:1:12;

%6.西南-西：225-270度
windfarmcluster_wind_direction_SW_W=225:5:270;
windfarmcluster_wind_speed_SW_W=3:1:5;


%7.西-西北：270-325度
windfarmcluster_wind_direction_W_NW=270:5:325;
windfarmcluster_wind_speed_W_NW=3:1:5;

%8.西北-北：325-360度
windfarmcluster_wind_direction_NW_N=325:5:360;
windfarmcluster_wind_speed_NW_N=3:1:5;

%% 初始化偏航设置
matrix=zeros(1,159);

%% 不同类型机组的设置
sqz_1=cell2mat(readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B10:B10'));              %青州1风机个数
sqz_2=cell2mat(readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B11:B11'));              %青州2风机个数
sqz_3=cell2mat(readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B12:B12'));              %青州3风机个数
turbine_diameter_vector=[cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','B3:B3')),...
                cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','E3:E3')),...
                cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','H3:H3'))];
turbine_hub_height_vector=[cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','B4:B4')),...
                cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','E4:E4')),...
                cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','H4:H4'))];
rated_power_vector=[cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','B13:B13')),...
                cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','E13:E13')),...
                cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','H13:H13'))];
life_total_vector=[cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','B15:B15')),...
                cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','E15:E15')),...
                cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','H15:H15'))];
repair_c_vector=[cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','B16:B16')),...
                cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','E16:E16')),...
                cell2mat(readcell('inputs_all_fields.xlsx','Sheet','Turbine','Range','H16:H16'))];
sqz_12=sqz_1+sqz_2;


without_optimization_result=struct();
windspeed_parallel = 7:8; % 6, 7, 8, 9 m/s
swi_cellarr = cell(length(windspeed_parallel), 1);
yaw_cellarr = cell(length(windspeed_parallel), 1);
power_max_cellarr = cell(length(windspeed_parallel), 1);
p12_max_cellarr = cell(length(windspeed_parallel), 1);
p3_max_cellarr = cell(length(windspeed_parallel), 1);
optimized_resulut=struct();
fatigue_0=zeros(159,1);
delete(gcp('nocreate'))
parpool('local', length(windspeed_parallel))
tic
% initialize parallel pool with the number of wind speeds
parfor ind_vel = 1:length(windspeed_parallel)
    swi_cellarr{ind_vel} = SmartWindInterface_yaw(sqz_12, turbine_diameter_vector, turbine_hub_height_vector, ...
                rated_power_vector, life_total_vector, repair_c_vector, matrix, fatigue_0, 0, windspeed_parallel(ind_vel));
    swi_cellarr{ind_vel}.windfield.wake.velocity_model = 'Huadian';
    swi_cellarr{ind_vel}.windfield.wake.deflection_model = 'Huadian';
    swi_cellarr{ind_vel}.windfield.wake.turbulence_model = 'Huadian';
    swi_cellarr{ind_vel}.windfield.enable_wfr = 'N0';
    swi_cellarr{ind_vel}.windfield.resolution = [20 10 5];
    % save results
    swi_cellarr{ind_vel}.yaw_parallel_test();
end
% I don't understand, why the parfor loop doesn't function correctly with power array assignment in the parfor loop.
for ind_vel = 1:length(windspeed_parallel)
    power_max_cellarr{ind_vel} = swi_cellarr{ind_vel}.get_farm_power();
    p12_max_cellarr{ind_vel} = swi_cellarr{ind_vel}.get_farm_qingzhou12_power();
    p3_max_cellarr{ind_vel} = swi_cellarr{ind_vel}.get_farm_qingzhou3_power();
end
toc


%% Non Parallel mode
tic
windspeed_parallel = 7:8; % 6, 7, 8, 9 m/s
swi_cellarr_nonpar = cell(length(windspeed_parallel), 1);
yaw_cellarr_nonpar = cell(length(windspeed_parallel), 1);
power_max_cellarr_nonpar = cell(length(windspeed_parallel), 1);
p12_max_cellarr_nonpar = cell(length(windspeed_parallel), 1);
p3_max_cellarr_nonpar = cell(length(windspeed_parallel), 1);
% initialize parallel pool with the number of wind speeds
% delete(gcp('nocreate'))
M = 0; % parallel/nonparallel mode
% parpool('local', length(windspeed_parallel))
for ind_vel = 1:length(windspeed_parallel)
    swi_cellarr_nonpar{ind_vel} = SmartWindInterface_yaw(sqz_12, turbine_diameter_vector, turbine_hub_height_vector, ...
                rated_power_vector, life_total_vector, repair_c_vector, matrix, fatigue_0, 0, windspeed_parallel(ind_vel));
    swi_cellarr_nonpar{ind_vel}.windfield.wake.velocity_model = 'Huadian';
    swi_cellarr_nonpar{ind_vel}.windfield.wake.deflection_model = 'Huadian';
    swi_cellarr_nonpar{ind_vel}.windfield.wake.turbulence_model = 'Huadian';
    swi_cellarr_nonpar{ind_vel}.windfield.enable_wfr = 'N0';
    swi_cellarr_nonpar{ind_vel}.windfield.resolution = [20 10 5];
    % save results
    swi_cellarr_nonpar{ind_vel}.yaw_parallel_test();
    power_max_cellarr_nonpar{ind_vel} = swi_cellarr_nonpar{ind_vel}.get_farm_power();
    p12_max_cellarr_nonpar{ind_vel} = swi_cellarr_nonpar{ind_vel}.get_farm_qingzhou12_power();
    p3_max_cellarr_nonpar{ind_vel} = swi_cellarr_nonpar{ind_vel}.get_farm_qingzhou3_power();
end
toc