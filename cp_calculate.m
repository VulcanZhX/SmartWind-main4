% 新数据
data = [
0	0	0;
3	58	0.739;
3.5	125	0.747;
4	248	0.751;
4.5	426	0.755;
5	643	0.757;
5.5	923	0.759;
6	1260	0.759;
6.5	1648	0.76;
7	2105	0.76;
7.5	2642	0.76;
8	3271	0.761;
8.5	3970	0.75;
9	4686	0.713;
9.5	5430	0.678;
10	6212	0.645;
10.5	7014	0.613;
11	7824	0.583;
11.5	8300	0.521;
12	8300	0.439;
12.5	8300	0.379;
13	8300	0.331;
13.5	8300	0.292;
14	8300	0.259;
14.5	8300	0.232;
15	8300	0.208;
15.5	8300	0.188;
16	8300	0.171;
16.5	8300	0.155;
17	8300	0.142;
17.5	8300	0.13;
18	8300	0.12;
18.5	8300	0.111;
19	8300	0.102;
19.5	8300	0.095;
20	8300	0.088;
20.5	8300	0.082;
21	8300	0.077;
21.5	8300	0.072;
22	8300	0.068;
22.5	8300	0.063;
23	8300	0.06;
23.5	8300	0.056;
24	8300	0.053;
24.5	8300	0.05;
25	8300	0.048;
25.5	0	0;
26	0	0;
26.5	0	0;
27	0	0;
27.5	0	0;
28	0	0;
28.5	0	0;
29	0	0;
29.5	0	0;
30	0	0;
30.5	0	0;
31	0	0;
];

rho = 1.225; % 空气密度 kg/m^3
D = 180; % 叶轮直径 m
R = D/2;
A = pi * R^2; % 扫掠面积 m^2

wind_speed = data(:,1);
power_kW = data(:,2);
Ct = data(:,3);

power_W = power_kW * 1000; % 转换为瓦特

power_wind = 0.5 * rho * A .* (wind_speed.^3);

Cp_calc = zeros(size(power_W));
valid_idx = power_wind > 0; % 避免除零错误
Cp_calc(valid_idx) = power_W(valid_idx) ./ power_wind(valid_idx);

result = [wind_speed, power_kW, Ct, Cp_calc];

fprintf('风速(m/s)\t功率(kW)\tCt\t计算Cp\n');
for i = 1:length(wind_speed)
    fprintf('%.1f\t\t%.1f\t\t%.3f\t%.4f\n', result(i,1), result(i,2), result(i,3), result(i,4));
end
