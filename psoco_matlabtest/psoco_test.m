% fitness = @(x) sum(x.^2, 2); % 简单的平方和目标函数
% constraints = {@(x) x(:,1) + x(:,2) - 1}; % 约束 x1 + x2 <= 1



% objective function
fitness = @(x) ((x(:, 1)-2).^2 + (x(:, 2)-1).^2);
% constraints 1-3
cons1 = @(x) (x(:, 1)-2*x(:, 2)+1);
cons2 = @(x) -(x(:, 1)-2*x(:, 2)+1);
cons3 = @(x) 0.25*x(:, 1).^2 + x(:, 2).^2 - 1;

% cell array of constraint handlers
cons = {cons1, cons2, cons3};

pso_problem = PSOCO('particle_size', 100, 'max_iter', 200, 'sol_size', 2, 'fitness', fitness, 'constraints', cons);
pso_problem.init_Population(0, 1);
fitness_history = pso_problem.solve();
disp(['Best fitness: ', num2str(pso_problem.fit)]);
disp('Best solution:');
disp(pso.gbest);