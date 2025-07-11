clc
clear
close all
load y2_0_8_initial.mat

%% 场群风资源输入设置
% 风向扇区
wind_sectors = 8;

%风向划分，正北-东北：0-45度；东北-东：45-90度；东-东南：90-135度；东南-南：135-180；南-西南：180-225度；西南-西：225-270度；西-西北：270-325度；西北-北：325-360度
%1.正北-东北：0-45度
windfarmcluster_wind_direction_N_NE = 0:5:45;
windfarmcluster_wind_speed_N_NE = 3:1:12;

%2.东北-东：45-90度
windfarmcluster_wind_direction_NE_E = 45:5:90;
windfarmcluster_wind_speed_NE_E = 3:1:12;

%3.东-东南：90-135度
windfarmcluster_wind_direction_E_SE = 90:5:135;
windfarmcluster_wind_speed_E_SE = 3:1:10;

%4.东南-南：135-180
windfarmcluster_wind_direction_SE_S = 135:5:180;
windfarmcluster_wind_speed_SE_S = 3:1:10;

%5.南-西南：180-225度
windfarmcluster_wind_direction_S_SW = 180:5:225;
windfarmcluster_wind_speed_S_SW = 3:1:12;

%6.西南-西：225-270度
windfarmcluster_wind_direction_SW_W = 225:5:270;
windfarmcluster_wind_speed_SW_W = 3:1:5;

%7.西-西北：270-325度
windfarmcluster_wind_direction_W_NW = 270:5:325;
windfarmcluster_wind_speed_W_NW = 3:1:5;

%8.西北-北：325-360度
windfarmcluster_wind_direction_NW_N = 325:5:360;
windfarmcluster_wind_speed_NW_N = 3:1:5;

%% 初始化偏航设置
matrix = zeros(1, 159);

%% 不同类型机组的设置
sqz_1 = cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'WindField', 'Range', 'B10:B10')); %青州1风机个数
sqz_2 = cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'WindField', 'Range', 'B11:B11')); %青州2风机个数
sqz_3 = cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'WindField', 'Range', 'B12:B12')); %青州3风机个数
turbine_diameter_vector = [cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'B3:B3')), ...
                             cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'E3:E3')), ...
                             cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'H3:H3'))];
turbine_hub_height_vector = [cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'B4:B4')), ...
                               cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'E4:E4')), ...
                               cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'H4:H4'))];
rated_power_vector = [cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'B13:B13')), ...
                        cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'E13:E13')), ...
                        cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'H13:H13'))];
life_total_vector = [cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'B15:B15')), ...
                       cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'E15:E15')), ...
                       cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'H15:H15'))];
repair_c_vector = [cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'B16:B16')), ...
                     cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'E16:E16')), ...
                     cell2mat(readcell('inputs_all_fields.xlsx', 'Sheet', 'Turbine', 'Range', 'H16:H16'))];
sqz_12 = sqz_1 + sqz_2;

without_optimization_result = struct();
optimized_resulut = struct();
fatigue_0 = zeros(159, 1);

%% 初始化场群
swi_1 = SmartWindInterface_yaw(sqz_12, turbine_diameter_vector, turbine_hub_height_vector, rated_power_vector, life_total_vector, repair_c_vector, matrix, fatigue_0, 285, 6);
rng("default")
% swi.windfield.wind_direction=270;
swi_1.windfield.wake.velocity_model = 'Huadian';
swi_1.windfield.wake.deflection_model = 'Huadian';
swi_1.windfield.wake.turbulence_model = 'Huadian';
swi_1.windfield.enable_wfr = 'N0';
swi_1.windfield.resolution = [20 10 10];

swi_1.calculate_wake();
without_optimization_farm_power = swi_1.get_farm_power();
without_optimization_farm_yaw = swi_1.get_yaw_angles();

without_optimization_p12 = swi_1.get_farm_qingzhou12_power();
without_optimization_p3 = swi_1.get_farm_qingzhou3_power();
fatigue_1 = swi_1.get_turbines_life_coeff();

%% parfor loop to optimize yaw angles under different wind speed (wind direction is fixed at 0 degrees)
tic
windspeed_parallel = 6:1:9; % 6, 7, 8, 9 m/s
% winddirection_parallel = 0:15:90; % 270 + (0, 15, ..., 90 degrees)
% winddirection_parallel = 105:15:270; % 270 + (105, ..., 270 degrees) (real: 15, ..., 180 degrees)
winddirection_parallel = 285:15:345; % 270 + (285, ..., 345 degrees) (real: 195, ..., 255 degrees)
swi_cellarr = cell(length(windspeed_parallel) * length(winddirection_parallel), 1);
yaw_cellarr = cell(length(windspeed_parallel) * length(winddirection_parallel), 1);
power_max_cellarr = cell(length(windspeed_parallel) * length(winddirection_parallel), 1);
p12_max_cellarr = cell(length(windspeed_parallel) * length(winddirection_parallel), 1);
p3_max_cellarr = cell(length(windspeed_parallel) * length(winddirection_parallel), 1);

% initialize parallel pool with the number of wind speeds and directions
delete(gcp('nocreate'))
parpool('local', length(windspeed_parallel) * length(winddirection_parallel))

parfor ind_v_d = 1:length(windspeed_parallel) * length(winddirection_parallel)
    % calculate the index for wind speed and wind direction
    ind_v = floor((ind_v_d - 1) / length(winddirection_parallel)) + 1; % wind speed index
    ind_d = mod(ind_v_d - 1, length(winddirection_parallel)) + 1; % wind direction index
    % create SmartWindInterface_yaw object for each wind speed and direction
    swi_cellarr{ind_v_d} = SmartWindInterface_yaw(sqz_12, turbine_diameter_vector, turbine_hub_height_vector, ...
        rated_power_vector, life_total_vector, repair_c_vector, matrix, fatigue_0, ...
        winddirection_parallel(ind_d), windspeed_parallel(ind_v)); %#ok<PFBNS>
    swi_cellarr{ind_v_d}.windfield.wake.velocity_model = 'Huadian';
    swi_cellarr{ind_v_d}.windfield.wake.deflection_model = 'Huadian';
    swi_cellarr{ind_v_d}.windfield.wake.turbulence_model = 'Huadian';
    swi_cellarr{ind_v_d}.windfield.enable_wfr = 'N0';
    swi_cellarr{ind_v_d}.windfield.resolution = [20 10 10];
    % parallel optimization for each wind speed
    yaw_cellarr{ind_v_d} = swi_cellarr{ind_v_d}.yaw_optimization_pso_gb(0, 0);
end

for ind_v_d = 1:length(windspeed_parallel) * length(winddirection_parallel)
    power_max_cellarr{ind_v_d} = swi_cellarr{ind_v_d}.get_farm_power();
    p12_max_cellarr{ind_v_d} = swi_cellarr{ind_v_d}.get_farm_qingzhou12_power();
    p3_max_cellarr{ind_v_d} = swi_cellarr{ind_v_d}.get_farm_qingzhou3_power();
end

toc

%% Shutdown parallel pool and save results
delete(gcp('nocreate')) % shutdown parallel pool
% save('yawopt_main_maxpower_vars_vd.mat', "swi_cellarr", "yaw_cellarr", "power_max_cellarr", ...
%     "p12_max_cellarr", "p3_max_cellarr", "without_optimization_farm_power", ...
%     "without_optimization_farm_yaw", "without_optimization_p12", "without_optimization_p3");

% save('./vdmax_tracking_life_data/yawopt_main_maxpower_vars_vd_105_270_6_9.mat', ...
%     "swi_cellarr", "yaw_cellarr", "power_max_cellarr", ...
%     "p12_max_cellarr", "p3_max_cellarr", "without_optimization_farm_power", ...
%     "without_optimization_farm_yaw", "without_optimization_p12", "without_optimization_p3");

save('./vdmax_tracking_life_data/yawopt_main_maxpower_vars_vd_285_345_6_9.mat', ...
    "swi_cellarr", "yaw_cellarr", "power_max_cellarr", ...
    "p12_max_cellarr", "p3_max_cellarr", "without_optimization_farm_power", ...
    "without_optimization_farm_yaw", "without_optimization_p12", "without_optimization_p3");

% save('./vdmax_tracking_life_data/yawopt_main_maxpower_vars_vd_285_345_6_9.mat', ...
%     "swi_cellarr", "yaw_cellarr", "power_max_cellarr", ...
%     "p12_max_cellarr", "p3_max_cellarr", "without_optimization_farm_power", ...
%     "without_optimization_farm_yaw", "without_optimization_p12", "without_optimization_p3");
