function [z, meta] = get_z(t, p)
    % simulate vertical movement for a plastic particle
    % t: equally spaced datetime vector, length n
    % p: particle with scalar fields
    % returns: [z, meta], length n
    %       z: depth (m)
    %       meta: [rho_tot (kg m^-3), r_tot (m), I_z (micro mol quanta m^-2 s^-1)]
    % load the forcing to start with
    % no changes in lat/lon
    % let's load time/depth slices
    lon_range = [p.lon, p.lon];
    lat_range = [p.lat, p.lat];
    z_range = [0, 1e9];  % inf doesn't work
    t_range = [t(1), t(end)];
    S = load_4d_hyperslab(Paths.salinity, 'salinity', lon_range, lat_range, z_range, t_range);
    T = load_4d_hyperslab(Paths.temperature, 'water_temp', lon_range, lat_range, z_range, t_range);
    CHL = load_3d_hyperslab(Paths.chlorophyll, 'chlor_a', lon_range, lat_range, t_range);
    CHL.data = mean(CHL.data, 4, 'omitnan');
    CHL.time = CHL.time(1);  % for now, let's use a yearly average, to smooth nans
    
    PAR_SURF = get_surface_PAR(p.lat, p.lon, t);
    
    dt = seconds(t(2) - t(1));
    z = zeros(1, length(t));
    meta = zeros(length(t), 4);
    t_num = datenum(t);  % numeric time operations much faster
    for i=1:length(t)-1
        % get forcing data for this timestep
        S_z = S.select(p.lon, p.lat, p.z, t_num(i)); % g / kg
        T_z = T.select(p.lon, p.lat, p.z, t_num(i)); % celsius
        chl_surf = CHL.select(p.lon, p.lat, 0, t_num(i));  % mg m^-3
        chl_z = chl_vs_z_mixed(p.z, chl_surf);  % mg m^-3
        I_surf = PAR_SURF(i);   % micro mol quanta m^-2 s^-1
        chl_tot = get_chl_above_z_mixed(p.z, chl_surf); % mg m^-2
        I_z = get_light_at_z(p.z, I_surf, chl_tot);     % light at particle

        % record starting position at this timestep
        z(i) = p.z;  % record particle's location, m
        meta(i, 1) = p.rho_tot;  % record particle's total density, kg m^-3
        meta(i, 2) = p.r_tot;   % record particle's total radius, m
        meta(i, 3) = T_z;  % temperature at particle
        meta(i, 4) = I_z;  % light intensity at particle

        dAdt = get_algae_flux_for_particle(p, S_z, T_z, chl_z, I_z);
        p.A = p.A + dAdt * dt;

        % this approximates the position function, possibly poorly
        V_s = get_settling_velocity(p, S_z, T_z);
        p.z = p.z + V_s * dt;
        if p.z < 0  % constrain to surface
            p.z = 0;
        end
    end
    
    % record variables at final position
    z(i+1) = p.z;
    meta(i+1, 1) = p.rho_tot;  % record particle's total density, kg m^-3
    meta(i+1, 2) = p.r_tot;   % record particle's total radius, m
    meta(i, 3) = T_z;  % temperature at particle
    meta(i, 4) = I_z;  % light intensity at particle
end