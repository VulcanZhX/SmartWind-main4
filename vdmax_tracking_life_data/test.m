for i = 1:20
    if norm(yaw_cellarr{i}) < 1e-7
        disp(i);
    end
end