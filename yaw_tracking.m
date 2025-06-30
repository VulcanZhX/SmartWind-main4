clear
load("swi_2_maximum.mat")
tic

p12_agc = p12_max - 4e6; p3_agc = p3_max - 6e5;
swi_2.yaw_optimization_gb_life(p12_agc, p3_agc);

toc
optimized_wind_farm_generation=swi_2.get_farm_objective();
optimized_wind_farm_yaw=swi_2.get_yaw_angles();
swi_2.calculate_wake();
figure(2)
