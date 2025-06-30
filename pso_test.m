fun = @(x)x(1)*exp(-norm(x)^2);
rng default  % For reproducibility
nvars = 2;
lb = [-10,-15];
ub = [15,20];
[x, fval] = particleswarm(fun,nvars,lb,ub);
disp('Best solution found:');
disp(x);
disp('Function value at best solution:');
disp(fun(x));