classdef PSOCO
    % Particle Swarm Optimization Constraint Optimization
    % Author: Jing Wang (jingw2@foxmail.com)
    
    properties
        c1 = 2;
        c2 = 2;
        w = 1.2; % will decrease to 0.1
        kai = 0.73;
        vmax = 4;
        particle_size = 2000;
        max_iter = 1000;
        sol_size = 7;
        
        X; % particle positions
        V; % particle velocities
        pbest; % personal best positions
        gbest; % global best position
        p_fit; % personal best fitness values
        fit = inf; % global best fitness value
        iter = 1;
        
        constraints; % cell array of function handles
        sub_fitness; % fitness function handle
    end
    
    methods
        function obj = PSOCO(varargin)
            % Constructor with optional parameters as name-value pairs
            p = inputParser;
            addParameter(p, 'particle_size', 2000);
            addParameter(p, 'max_iter', 1000);
            addParameter(p, 'sol_size', 7);
            addParameter(p, 'fitness', []);
            addParameter(p, 'constraints', []);
            parse(p, varargin{:});
            
            obj.particle_size = p.Results.particle_size;
            obj.max_iter = p.Results.max_iter;
            obj.sol_size = p.Results.sol_size;
            obj.sub_fitness = p.Results.fitness;
            obj.constraints = p.Results.constraints;
            
            if isempty(obj.sub_fitness) || ~isa(obj.sub_fitness, 'function_handle')
                error('Fitness must be a function handle!');
            end
            
            if ~isempty(obj.constraints)
                if ~iscell(obj.constraints)
                    error('Constraints must be a cell array of function handles or empty!');
                end
                for i = 1:length(obj.constraints)
                    if ~isa(obj.constraints{i}, 'function_handle')
                        error('Each constraint must be a function handle!');
                    end
                end
            end
            
            obj.X = zeros(obj.particle_size, obj.sol_size);
            obj.V = zeros(obj.particle_size, obj.sol_size);
            obj.pbest = zeros(obj.particle_size, obj.sol_size);
            obj.gbest = zeros(1, obj.sol_size);
            obj.p_fit = inf(obj.particle_size, 1);
        end
        
        function val = fitness(obj, X, k)
            % fitness function + penalty
            obj_val = obj.sub_fitness(X);
            if size(obj_val,2) > 1
                obj_val = obj_val(:);
            end
            val = obj_val + obj.h(k) * obj.H(X);
        end
        
        function init_Population(obj, low, high)
            % Initialize particles
            if nargin < 3
                low = 0;
                high = 1;
            end
            obj.X = low + (high - low) * rand(obj.particle_size, obj.sol_size);
            obj.V = rand(obj.particle_size, obj.sol_size);
            obj.pbest = obj.X;
            obj.p_fit = obj.fitness(obj.X, 1);
            [best, best_idx] = min(obj.p_fit);
            if best < obj.fit
                obj.fit = best;
                obj.gbest = obj.X(best_idx, :);
            end
        end
        
        function fitness_history = solve(obj)
            % Solve optimization problem
            fitness_history = zeros(obj.max_iter, 1);
            w_step = (obj.w - 0.1) / obj.max_iter;
            for k = 1:obj.max_iter
                tmp_obj = obj.fitness(obj.X, k);
                
                % Update pbest
                improved = tmp_obj < obj.p_fit;
                obj.p_fit(improved) = tmp_obj(improved);
                obj.pbest(improved, :) = obj.X(improved, :);
                
                % Update gbest
                [best, best_idx] = min(obj.p_fit);
                if best < obj.fit
                    obj.fit = best;
                    obj.gbest = obj.X(best_idx, :);
                end
                
                % Update velocity and position
                rand1 = rand(obj.particle_size, obj.sol_size);
                rand2 = rand(obj.particle_size, obj.sol_size);
                obj.V = obj.kai * (obj.w * obj.V + obj.c1 * rand1 .* (obj.pbest - obj.X) + ...
                    obj.c2 * rand2 .* (repmat(obj.gbest, obj.particle_size, 1) - obj.X));
                
                obj.V(obj.V > obj.vmax) = obj.vmax;
                obj.V(obj.V < -obj.vmax) = -obj.vmax;
                
                obj.X = obj.X + obj.V;
                
                fitness_history(k) = obj.fit;
                obj.w = obj.w - w_step;
            end
        end
        
        function qscore = q(~, g)
            % relative violated function
            qscore = max(0, g);
        end
        
        function gamma_val = gamma(~, qscore)
            % power of penalty function
            gamma_val = zeros(size(qscore));
            gamma_val(qscore >= 1) = 2;
            gamma_val(qscore < 1) = 1;
        end
        
        function theta_val = theta(~, qscore)
            % multi-assignment function
            theta_val = zeros(size(qscore));
            theta_val(qscore < 0.001) = 10;
            theta_val(qscore <= 0.1) = 10;
            theta_val(qscore <= 1) = 100;
            theta_val(qscore > 1) = 300;
        end
        
        function val = h(~, k)
            % penalty score
            val = k * sqrt(k);
        end
        
        function res = H(obj, X)
            % penalty factor
            res = 0;
            if isempty(obj.constraints)
                return;
            end
            for i = 1:length(obj.constraints)
                cons_func = obj.constraints{i};
                g = cons_func(X);
                qscore = obj.q(g);
                if isvector(qscore) || size(qscore,2) == 1
                    qscore = reshape(qscore, [], 1);
                    res = res + sum(obj.theta(qscore) .* (qscore .^ obj.gamma(qscore)));
                else
                    for j = 1:size(qscore,2)
                        qscorei = qscore(:, j);
                        qscorei = reshape(qscorei, [], 1);
                        res = res + sum(obj.theta(qscorei) .* (qscorei .^ obj.gamma(qscorei)));
                    end
                end
            end
        end
    end
end
