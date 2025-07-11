clear
clc
load('../yaw_tracking_results.mat')

rng default % For reproducibility
% Load the data
n_turbs = 159;
% swi_6_270_1 = swi_cellarr{1}.windfield.turbinechart.turbines{12};
% swi_6_270_1.past_comprehensive_fatigue_coefficient
% swi_6_270_1.comprehensive_fatigue_coefficient
disp(swi_cellarr{1}.get_farm_life_coeff())
disp(swi_cellarr{1}.get_farm_loss());

swi_cellarr{1}.set_yaw_angles(zeros(n_turbs, 1));
swi_cellarr{1}.calculate_wake();
disp(swi_cellarr{1}.get_farm_life_coeff())
disp(swi_cellarr{1}.get_farm_loss());

% generate yaw_angle-farm_loss-power data points
yaw_angle_fct = 0:30;
basic_yaw = -1 + 2*rand(n_turbs, 1); % random yaw angles between -1 and 1
swi_case1 = swi_cellarr{1};

yaw_fatigue_power = zeros(length(yaw_angle_fct), 3);
for i = 1:length(yaw_angle_fct)
    swi_case1.set_yaw_angles(yaw_angle_fct(i)*basic_yaw);
    swi_case1.calculate_wake();
    yaw_fatigue_power(i, 1) = yaw_angle_fct(i);
    yaw_fatigue_power(i, 2) = swi_case1.get_farm_loss();
    yaw_fatigue_power(i, 3) = swi_case1.get_farm_power();
end

save('yaw_fatigue.mat', 'yaw_fatigue_power');