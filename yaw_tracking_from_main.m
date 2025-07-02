clear

%% Load data
load("yawopt_main_maxpower_vars.mat");

windspeed_parallel = 6:9; % 6, 7, 8, 9 m/s
yaw_track_arr = cell(length(windspeed_parallel), 1);
power_track_arr = cell(length(windspeed_parallel), 1);
p12_track_arr = cell(length(windspeed_parallel), 1);
p3_track_arr = cell(length(windspeed_parallel), 1);

% construct power agc
power_agc12_cellarr = p12_max_cellarr;
power_agc3_cellarr = p3_max_cellarr;

for id = 1:length(windspeed_parallel)
    power_agc12_cellarr{id} = 0.99 * power_agc12_cellarr{id};
    power_agc3_cellarr{id} = 0.99 * power_agc3_cellarr{id};
end

% initialize parallel pool with the number of wind speeds
delete(gcp('nocreate'))
parpool('local', length(windspeed_parallel))
tic
parfor ind_vel = 1:length(windspeed_parallel)
    yaw_track_arr{ind_vel} = swi_cellarr{ind_vel}.yaw_optimization_pso_gb_tracking(power_agc12_cellarr{ind_vel}, power_agc3_cellarr{ind_vel});
end
fprintf("elapsed time for yaw tracking: %.2f seconds\n", toc);

% record tracking results
for ind_vel = 1:length(windspeed_parallel)
    power_track_arr{ind_vel} = swi_cellarr{ind_vel}.get_farm_power();
    p12_track_arr{ind_vel} = swi_cellarr{ind_vel}.get_farm_qingzhou12_power();
    p3_track_arr{ind_vel} = swi_cellarr{ind_vel}.get_farm_qingzhou3_power();
end

% save results
save('yaw_tracking_results.mat', "yaw_track_arr", "power_track_arr", ...
    "p12_track_arr", "p3_track_arr", "power_agc12_cellarr", "power_agc3_cellarr");