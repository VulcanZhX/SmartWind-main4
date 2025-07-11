classdef Windfield < handle
    
    properties
        wind_speed%=cell2mat(readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B3:B3'));           %风速
        wind_direction_real%=cell2mat(readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B4:B4'));       %风向
        turbulence_intensity=cell2mat(readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B5:B5')); %湍流强度
        added_turbulence_intensity=1;%cell2mat(readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B13:B13')); %附加湍流强度



        wind_shear=cell2mat(readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B6:B6'));           %风切变
        wind_veer=cell2mat(readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B7:B7'));            %风向切变
        specified_wind_height=cell2mat(readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B9:B9'));%风高
        enable_wfr=readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B15:B15');                   %是否启用风场计算
        resolution=cell2mat(readcell('inputs_all_fields.xlsx','Sheet','WindField','Range','B16:B18'));         %xyz方向上网格划分的分辨率
        turbinechart                                                                                           %存储整场风机布局对象
        wake                                                                                                   %存储尾流模型对象
        u                                                                                                      %初始和计算后的风速场
        turbulence                                                                                              %初始和计算后的湍流场
    end

    properties (Dependent)
        bounds                                                    %风场边界
        x
        y
        z                                                         %风场网格坐标
        u_initial                                                 %初始风速场
        turbulence_initial
    end
    
    methods

        function obj=Windfield(turbinechart,winddirection,windvelocity,wake)
            obj.turbinechart=turbinechart;
            obj.wake=wake;
            obj.wind_direction_real=winddirection;
            obj.wind_speed=windvelocity;
        end
        
        %% 计算风场边界
        function bounds=get.bounds(obj)
            coords_x=obj.turbinechart.coordinates(:,1);           %所有涡轮机x方向上的坐标
            coords_y=obj.turbinechart.coordinates(:,2);           %所有涡轮机y方向上的坐标
            h=obj.turbinechart.coordinates(1,3);                  %涡轮机所在高度
            d=obj.turbinechart.turbines{1}.rotor_diameter;        %风机转子直径
            x_min=min(coords_x)-2*d;                              %x坐标的最小值-2倍转子直径
            x_max=max(coords_x)+10*d;                             %x坐标最大值+10倍转子直径
            y_min=min(coords_y)-2*d;                              %y坐标最小值+2倍转子直径
            y_max=max(coords_y)+2*d;                              %y坐标最大值+2倍转子直径
            z_min=0.1;                                            %z坐标最小值，超出地面
            z_max=4*h;                                            %z坐标最大值，4倍轮毂高度 
            bounds=[x_min,x_max,y_min,y_max,z_min,z_max];         %风场边界
        end

        %% 轮毂高度处沿风向方向望去的风机周围形成的网格，其中各网格处的x坐标
        function x=get.x(obj)
            if strcmp(obj.enable_wfr,'No')
               x=zeros(sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   length(obj.turbinechart.layout_x));            %layout的行大小代表了风机个数
               for i=1:length(obj.turbinechart.layout_x)
                   x(:,:,i)=obj.turbinechart.layout_x(i);
               end
            else
                 bd=obj.bounds;
                 res=obj.resolution;
                 x_direction=linspace(bd(1),bd(2),res(1));
                 y_direction=linspace(bd(3),bd(4),res(2));
                 z_direction=linspace(bd(5),bd(6),res(3));
                 [~,yy,~]=meshgrid(y_direction,x_direction,z_direction);
                 x=yy;
            end
        end

        %% 轮毂高度处沿风向方向望去的风机周围形成的网格，其中各网格处的y坐标
        function y=get.y(obj)
            if strcmp(obj.enable_wfr,'No')
               y=zeros(sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   length(obj.turbinechart.layout_x));
               for i=1:length(obj.turbinechart.layout_x)
                   radius=obj.turbinechart.turbines{i,1}.rotor_radius;
                   vector=linspace(-radius,radius,sqrt(obj.turbinechart.turbines{i,1}.points_turbine_grid))+obj.turbinechart.layout_y(i);
                   for j=1:sqrt(obj.turbinechart.turbines{i,1}.points_turbine_grid)
                       y(j,:,i)=vector;
                   end
               end
            else
                 bd=obj.bounds;
                 res=obj.resolution;
                 x_direction=linspace(bd(1),bd(2),res(1));
                 y_direction=linspace(bd(3),bd(4),res(2));
                 z_direction=linspace(bd(5),bd(6),res(3));
                 [xx,~,~]=meshgrid(y_direction,x_direction,z_direction);
                 y=xx;
            end
        end

        %% 轮毂高度处沿风向方向望去的风机周围形成的网格，其中各网格处的z坐标
        function z=get.z(obj)            
            if strcmp(obj.enable_wfr,'No')
               z=zeros(sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   length(obj.turbinechart.layout_x));
               for i=1:length(obj.turbinechart.layout_x)
                   radius=obj.turbinechart.turbines{i,1}.rotor_radius;
                   vector=linspace(-radius,radius,sqrt(obj.turbinechart.turbines{i,1}.points_turbine_grid))+obj.turbinechart.layout_z(i);
                   for k=1:sqrt(obj.turbinechart.turbines{i,1}.points_turbine_grid)
                       z(:,k,i)=flip(vector);
                   end
               end
            else
                 bd=obj.bounds;
                 res=obj.resolution;
                 x_direction=linspace(bd(1),bd(2),res(1));
                 y_direction=linspace(bd(3),bd(4),res(2));
                 z_direction=linspace(bd(5),bd(6),res(3));
                 [~,~,z]=meshgrid(y_direction,x_direction,z_direction);
            end
        end
        
        %% 初始化场群各网格点处的风速，沿风向方向
        function u_initial=get.u_initial(obj)
            h=obj.turbinechart.turbines{1,1}.hub_height;
            u_initial=obj.wind_speed*(obj.z/h).^obj.wind_shear;
        end

        %% 初始化场群各网格点处的附加湍流强度(所有的附加湍流强度均为0)
        function turbulence_initial=get.turbulence_initial(obj)
            h=obj.turbinechart.turbines{1,1}.hub_height;
            turbulence_initial=obj.added_turbulence_intensity*(obj.z/h);
        end


%         function v_initial=get.v_initial(obj)
%             v_initial=zeros(size(obj.u_initial));
%         end
% 
%         function w_initial=get.w_initial(obj)
%             w_initial=zeros(size(obj.u_initial));
%         end
        %% 风向改变后各网格点的坐标
        function [rotated_x,rotated_y,rotated_z]=rotate_grid(obj,center) %基于风向对坐标进行旋转，风向改变前排机组变化
            wind_direction=encase180(obj.wind_direction_real-270);
            x_offset=obj.x-center(1);
            y_offset=obj.y-center(2);
            rotated_x=x_offset*cosd(wind_direction)-y_offset*sind(wind_direction)+center(1);
            rotated_y=x_offset*sind(wind_direction)+y_offset*cosd(wind_direction)+center(2);
            rotated_z=obj.z;
        end

        % function set.wind_direction(obj,value)
        %     obj.wind_direction=encase180(value-270);
        % end

        %% 计算当前风机i在下游产生的尾流赤字
        function obj=calculatewake(obj)%风场对象
            wind_direction=encase180(obj.wind_direction_real-270);

            %% 风向改变后，风机旋转坐标
            u_init=obj.u_initial;                                                 %场群所有网格点的初始风速
            obj.u=u_init;

            turbulence_init=obj.turbulence_initial;                               %场群所有网格点的初始湍流强度
            obj.turbulence=turbulence_init;

            % wake_sign='1';
            % turbulence_sign='0';


            bd=obj.bounds;                                                        %风场边界信息
            center=[mean([bd(1),bd(2)])...
                   ,mean([bd(3),bd(4)]),0];                                       %风场中心位置坐标
            rotated_chart=obj.turbinechart.rotated(center,wind_direction);    %依据当前风向确定的旋转风机坐标图



            %% 风向改变，各风机坐标旋转后对应的网格坐标
            [rotated_x,rotated_y,rotated_z]=obj.rotate_grid(center);              %旋转风机后对应的网格坐标

            %% 风机排序
            sorted_chart=obj.turbinechart.sortinx(rotated_chart);                 %按x坐标的先后顺序进行排序
            [sorted_coords,~,sorted_indexes]=extract_features_tc(sorted_chart);   %一次获取排序后的风机坐标和索引，3维和1维

            % 湍流
            if strcmp(obj.wake.turbulence_choice,'Yes') || strcmp(obj.wake.velocity_model,'Huadian') || strcmp(obj.wake.deflection_model,'Huadian')
               for i=1:length(obj.turbinechart.layout_x)
                   obj.turbinechart.turbines{sorted_indexes(i),1}.turbulence=obj.turbulence_intensity;   %将期望的湍流强度赋值给排序后相应风机的湍流强度
               end
            end
            u_wake=zeros(size(obj.u));                                                                   %所有网格点处的单个尾流损失
            u_turbulence_wake=zeros(size(obj.u));                                                        %所有网格点处的单个湍流强度
 
           
           %% 遍历所有风机，并计算风机在其他网格点产生的尾流
            for i=1:length(obj.turbinechart.layout_x)
                obj.turbinechart.turbines{sorted_indexes(i),1}.update_velocities(u_wake,obj,...
                sorted_coords(i,:),rotated_x,rotated_y,rotated_z,u_init,sorted_indexes(i));

                %当前风机i在其他网格点处产生的尾流偏转
                [deflection]=obj.wake.deflection_function(rotated_x,...
                    rotated_y,obj.turbinechart.turbines{sorted_indexes(i),1},...
                    sorted_coords(i,:),obj,u_init);

                %当前风机i在其他网格点处产生的尾流
                [turb_u_wake,~,~]=obj.wake.velocity_function...
                    (rotated_x,rotated_y,rotated_z,obj.turbinechart.turbines{sorted_indexes(i),1},...
                    sorted_coords(i,:),deflection,obj,u_init);

                %当前风机i在其他网格点处产生的湍流强度
                turbulence_calculate_one=obj.wake.turbulence_function...
                    (rotated_x,rotated_y,rotated_z,obj.turbinechart.turbines{sorted_indexes(i),1},...
                    sorted_coords(i,:),deflection,obj,turbulence_init);

                obj.turbinechart.turbines{sorted_indexes(i),1}.update_turbulence_intensity(obj,...
                sorted_coords(i,:),rotated_x,rotated_y,rotated_z,u_turbulence_wake,sorted_indexes(i));
                % if strcmp(obj.wake.turbulence_choice,'Yes') || strcmp(obj.wake.velocity_model,'Gauss') || strcmp(obj.wake.deflection_model,'Gauss')%在满足特定条件下，计算风机之间的相互影响
                %     for j=1:length(obj.turbinechart.layout_x)%对风机布局中的每一个风机进行遍历。
                %         if sorted_coords(j,1)>sorted_coords(i,1) && abs(sorted_coords(j,2)-sorted_coords(i,2))<2*obj.turbinechart.turbines{sorted_indexes(i),1}.rotor_diameter%如果当前遍历到的风机j沿风向的水平坐标大于大于风机i，且垂直位置差小于两倍风机i的叶轮直径，则执行以下操作。
                % 
                %            %计算未受干扰时风机 j 的风速分布。
                %            undisturbed_velocities=obj.turbinechart.turbines{sorted_indexes(j),1}.calculate_turbine_velocities(u_init,sorted_coords(j,:),rotated_x,rotated_y,rotated_z,obj,sorted_indexes(j));
                % 
                %            %计算受尾流影响时风机 j 的风速分布。
                %            disturbed_velocities=obj.turbinechart.turbines{sorted_indexes(j),1}.calculate_turbine_velocities(u_init-turb_u_wake,sorted_coords(j,:),rotated_x,rotated_y,rotated_z,obj,sorted_indexes(j));
                % 
                %            %计算未受干扰和受干扰时风速分布的重叠区域，并根据重叠区域大小更新风机j的湍流强度。
                %            area_overlap=obj.calculate_overlap(undisturbed_velocities,disturbed_velocities,obj.turbinechart.turbines{sorted_indexes(j),1});
                %            if area_overlap>0
                %                obj.turbinechart.turbines{sorted_indexes(j),1}.update_turbulence_intensity(obj,obj.wake,sorted_coords(j,:),sorted_coords(i,:),obj.turbinechart.turbines{sorted_indexes(i),1},area_overlap);
                %            end
                %         end
                %      end
                % end
                u_wake=obj.wake.combination_function(u_wake,turb_u_wake);
                u_turbulence_wake=obj.wake.turbulence_combination_function(u_turbulence_wake,turbulence_calculate_one);

            end

            obj.u=u_init-u_wake;
            obj.turbulence=u_turbulence_wake;

        end

        %% 不考虑尾流影响下的风场速度分布
        function obj=calculatenowake(obj)%不考虑尾流影响下的风机速度场
            wind_direction=encase180(obj.wind_direction_real-270);
            u_init=obj.u_initial;
            obj.u=obj.u_initial;            
            bd=obj.bounds;
            center=[mean([bd(1),bd(2)])...
                   ,mean([bd(3),bd(4)]),0];
            rotated_chart=obj.turbinechart.rotated(center,wind_direction);
            [rotated_x,rotated_y,rotated_z]=obj.rotate_grid(center);
            [rotated_coords,~,rotated_indexes]=extract_features_tc(rotated_chart);
            u_wake=zeros(size(obj.u));
            for i=1:length(obj.turbinechart.layout_x)
                obj.turbinechart.turbines{rotated_indexes(i),1}.update_velocities(u_wake,obj,...
                rotated_coords(i,:),rotated_x,rotated_y,rotated_z,u_init,i);
            end            
        end
      

        %% 识别不受其他风机尾流影响的风机 
        function not_affecting_turbines=calculate_affturbines(obj)
            wind_direction=encase180(obj.wind_direction_real-270);
            u_init=obj.u_initial;                                                                   %%所有网格点处的初始风速
            obj.u=u_init; 

            turbulence_init=obj.turbulence_initial;                                                 %%场群所有网格点的初始湍流强度
            obj.turbulence=turbulence_init;
            
            % wake_sign='1';
            % turbulence_sign='0';
            %% 尾流赤字评估矩阵
            wake_matrix=zeros(length(obj.turbinechart.layout_x));                                   %%size:37x37；各风机在风场中其他风机位置处产生的尾流
            bd=obj.bounds;                                                                          %%风场边界
            center=[mean([bd(1),bd(2)])...
                   ,mean([bd(3),bd(4)]),0];                                                         %%风场中心
            rotated_chart=obj.turbinechart.rotated(center,wind_direction);                      %% 依据当前风场风向和边界确定旋转后的风机坐标
            [rotated_x,rotated_y,rotated_z]=obj.rotate_grid(center);                                %%各网格点依据当前中心和风向旋转后的坐标
            sorted_chart=obj.turbinechart.sortinx(rotated_chart);                                   %%按x坐标大小排序后的风机
            [sorted_coords,~,sorted_indexes]=extract_features_tc(sorted_chart);                     %%分别提取排序后的风机坐标和其对应的风机索引
            for i=1:length(obj.turbinechart.layout_x)
                obj.turbinechart.turbines{sorted_indexes(i),1}.turbulence=obj.turbulence_intensity; %%指定重新排序后各风机的湍流强度，迎风向排序
            end
            u_wake=zeros(size(obj.u));                                                              %%size:同网格点大小
            u_turbulence_wake=zeros(size(obj.u));                                                        %所有网格点处的单个湍流强度


            for i=1:length(obj.turbinechart.layout_x)                                               %%风机循环
                obj.turbinechart.turbines{sorted_indexes(i),1}.update_velocities(u_wake,obj,...
                sorted_coords(i,:),rotated_x,rotated_y,rotated_z,u_init,sorted_indexes(i));         %%从迎风向的第一台风机开始，计算尾流影响后当前风机各网格点处的风速
                
                [deflection]=obj.wake.deflection_function(rotated_x,...
                    rotated_y,obj.turbinechart.turbines{sorted_indexes(i),1},...
                    sorted_coords(i,:),obj,u_init);                                                 %%当前风机的各网格点在其他风机坐标处产生的尾流偏转
                
                [turb_u_wake,~,~]=obj.wake.velocity_function...
                    (rotated_x,rotated_y,rotated_z,obj.turbinechart.turbines{sorted_indexes(i),1},...
                    sorted_coords(i,:),deflection,obj,u_init);                                      %%当前风机的各网格点在其他风机坐标处产生的尾流赤字
                
                turbulence_calculate_one=obj.wake.turbulence_function...
                    (rotated_x,rotated_y,rotated_z,obj.turbinechart.turbines{sorted_indexes(i),1},...
                    sorted_coords(i,:),deflection,obj,turbulence_init);
                % for j=1:length(obj.turbinechart.layout_x)
                %     if sorted_coords(j,1)>sorted_coords(i,1) %&& abs(sorted_coords(j,2)-sorted_coords(i,2))<2*obj.turbinechart.turbines{sorted_indexes(i),1}.rotor_diameter %%排序后风机j的x轴坐标大于当前风机i的x轴坐标，也就是流向坐标
                %        undisturbed_velocities=obj.turbinechart.turbines{sorted_indexes(j),1}.calculate_turbine_velocities(u_init,sorted_coords(j,:),rotated_x,rotated_y,rotated_z,obj,sorted_indexes(j)); %%未受尾流影响，当前风机各网格点处的风速
                %        disturbed_velocities=obj.turbinechart.turbines{sorted_indexes(j),1}.calculate_turbine_velocities(u_init-turb_u_wake,sorted_coords(j,:),rotated_x,rotated_y,rotated_z,obj,sorted_indexes(j)); %%受尾流影响，当前风机各网格点处的风速
                %        area_overlap=obj.calculate_overlap(undisturbed_velocities,disturbed_velocities,obj.turbinechart.turbines{sorted_indexes(j),1});
                %        if area_overlap>0 %%受影响网格点的比例大于0
                %            wake_matrix(sorted_indexes(i),sorted_indexes(j))=1;
                %            obj.turbinechart.turbines{sorted_indexes(j),1}.update_turbulence_intensity(obj,obj.wake,sorted_coords(j,:),sorted_coords(i,:),obj.turbinechart.turbines{sorted_indexes(i),1},area_overlap);
                %        end
                %     end
                % end
                u_turbulence_wake=obj.wake.combination_function(u_turbulence_wake,turbulence_calculate_one);
                u_wake=obj.wake.turbulence_combination_function(u_wake,turb_u_wake);                           %%在当前风场中叠加所有风机产生的尾流赤字
            end
            not_affecting_turbines=find(all(wake_matrix==0,2));                                     %%找出全为0的列
        end

        %% 获取按某种顺序排列的风机索引列表
        function sorted_indexes=get_ordered_turbines(obj)
            wind_direction=encase180(obj.wind_direction_real-270);
            bd=obj.bounds;
            center=[mean([bd(1),bd(2)])...
                   ,mean([bd(3),bd(4)]),0];
            rotated_chart=obj.turbinechart.rotated(center,wind_direction);
            sorted_chart=obj.turbinechart.sortinx(rotated_chart);
            [~,~,sorted_indexes]=extract_features_tc(sorted_chart);
        end
    end


    %% 该方法用于计算受影响区域的重叠程度，即受扰动速度影响的点数与总网格点数的比例。
    methods (Static)
        function disturbance=calculate_overlap(undisturbed_velocity,disturbed_velocity,turbine)
            affected_points=sum(undisturbed_velocity-disturbed_velocity>0.00000000000000001);
            disturbance=affected_points/length(turbine.grid);                                       %%速度差大于0.05的网格点占所有网格点的比例
        end
    end

end

