%% Life optimization and power tracking

clear
load("yaw_tracking_results.mat");

windspeed_parallel = 6:9; % 6, 7, 8, 9 m/s
yaw_lifecell_arr = cell(length(windspeed_parallel), 1);
power_lifecell_arr = cell(length(windspeed_parallel), 1);

fatigue_org = cell(length(windspeed_parallel), 1);
fatigue_opt = cell(length(windspeed_parallel), 1);

for ind_vel = 1:length(windspeed_parallel)
    fatigue_org{ind_vel} = swi_cellarr{ind_vel}.get_turbines_life_coeff();
end

delete(gcp('nocreate'))
parpool('local', length(windspeed_parallel))

tic
parfor ind_vel = 1:length(windspeed_parallel)
    yaw_lifecell_arr{ind_vel} = swi_cellarr{ind_vel}.yaw_optimization_gb_life(...
        power_agc12_cellarr{ind_vel}, power_agc3_cellarr{ind_vel});
end
toc

for ind_vel = 1:length(windspeed_parallel)
    swi_cellarr{ind_vel}.set_yaw_angles(yaw_lifecell_arr{ind_vel});
    swi_cellarr{ind_vel}.calculate_wake();
    power_lifecell_arr{ind_vel} = swi_cellarr{ind_vel}.get_farm_power();
    fatigue_opt{ind_vel} = swi_cellarr{ind_vel}.get_turbines_life_coeff();
end