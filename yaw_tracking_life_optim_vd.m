%% Life optimization and power tracking

clear
% load("yaw_tracking_results.mat");
% load("vdmax_tracking_life_data/yaw_tracking_results_vd_105_270_6_9.mat")
load("./vdmax_tracking_life_data/yaw_tracking_results_vd_285_345_6_9.mat");
windspeed_parallel = 6:9; % 6, 7, 8, 9 m/s
% winddirection_parallel = 105:15:270; % +105, 120, ..., 270 degrees
winddirection_parallel = 285:15:345; % +285, 300, ..., 345 degrees
yaw_lifecell_arr = cell(length(windspeed_parallel) * length(winddirection_parallel), 1);
power_lifecell_arr = cell(length(windspeed_parallel) * length(winddirection_parallel), 1);

loss_org = cell(length(windspeed_parallel) * length(winddirection_parallel), 1);
loss_opt = cell(length(windspeed_parallel) * length(winddirection_parallel), 1);

for ind_vel = 1:length(windspeed_parallel) * length(winddirection_parallel)
    loss_org{ind_vel} = swi_cellarr{ind_vel}.get_farm_loss();
end

delete(gcp('nocreate'))
parpool('local', length(windspeed_parallel) * length(winddirection_parallel));

tic

parfor ind_vel = 1:length(windspeed_parallel) * length(winddirection_parallel)
    yaw_lifecell_arr{ind_vel} = swi_cellarr{ind_vel}.yaw_pso_life_optimization( ...
        power_agc12_cellarr{ind_vel}, power_agc3_cellarr{ind_vel});
end

toc

for ind_vel = 1:length(windspeed_parallel) * length(winddirection_parallel)
    swi_cellarr{ind_vel}.set_yaw_angles(yaw_lifecell_arr{ind_vel});
    swi_cellarr{ind_vel}.calculate_wake();
    power_lifecell_arr{ind_vel} = swi_cellarr{ind_vel}.get_farm_power();
    loss_opt{ind_vel} = swi_cellarr{ind_vel}.get_farm_loss();
end

% save('yaw_tracking_life_vd_avg.mat', "loss_org", "loss_opt", "power_lifecell_arr", "power_track_arr",  "power_agc12_cellarr", ...
%     "power_agc3_cellarr", "yaw_lifecell_arr", "yaw_track_arr", "swi_cellarr");

% save('yaw_tracking_life_vd.mat', "loss_org", "loss_opt", "power_lifecell_arr", "power_track_arr", "power_agc12_cellarr", ...
%     "power_agc3_cellarr", "yaw_lifecell_arr", "yaw_track_arr", "swi_cellarr");

% save('./vdmax_tracking_life_data/yaw_tracking_life_vd_avg_105_270_6_9.mat', ...
%     "loss_org", "loss_opt", "power_lifecell_arr", "power_track_arr", "power_agc12_cellarr", ...
%     "power_agc3_cellarr", "yaw_lifecell_arr", "yaw_track_arr", "swi_cellarr");

save('./vdmax_tracking_life_data/yaw_tracking_life_vd_avg_285_345_6_9.mat', ... 
    "loss_org", "loss_opt", "power_lifecell_arr", "power_track_arr", "power_agc12_cellarr", ...
    "power_agc3_cellarr", "yaw_lifecell_arr", "yaw_track_arr", "swi_cellarr");