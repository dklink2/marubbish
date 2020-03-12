% create plots for presentation on march 3, 2020

%ave_depth_seasons();
%plot_NP_profile(50*1e-3, 3);
%plot_NP_profile(1*1e-3, 3);
%plot_NP_profile(.1*1e-3, 20);
plot_NP_profile(.01*1e-3, 10);
%plot_yearly_ave_depth();
%ave_depth_for_different_mortalities();
%plot_density_comparison(.1*1e-3);

function plot_density_comparison(r_pl)
    rho_pl = [kooi_constants.rho_HDPE, kooi_constants.rho_LDPE, kooi_constants.rho_PP];
    rho_label = {'HDPE', 'LDPE', 'PP'};
    lat = 34;  % roughly center of GPGP
    lon = -140;
    figure;
    ax = zeros(1, 3);
    for i=1:3
        t = datetime(2015, 1, 1, 0, 0, 0):hours(.25*pi):datetime(2017, 1, 1, 0, 0, 0);
        p = Particle(r_pl, rho_pl(i), 0, lat, lon, 0);
        [z, ~] = get_z(t, p);

        t = t - hours(9);  % convert from UTC to local time

        ax(i) = subplot(3, 1, i);
        plot(t, z);
        set(gca, 'ydir', 'reverse');
        ylabel('depth (m)');
        title(sprintf('%s, radius %.1f mm', rho_label{i}, r_pl*1000));
        xlim([t(1), t(end)]);
        %ylim([0, 300]);
    end
    linkaxes(ax);
end

function plot_NP_profile(r_pl, subset_days)
    t = datetime(2015, 1, 1, 0, 0, 0):hours(.25*pi):datetime(2018, 1, 1, 0, 0, 0);
    rho_pl = kooi_constants.rho_HDPE;

    lat = 34;  % roughly center of GPGP
    lon = -140;
    p = Particle(r_pl, rho_pl, 0, lat, lon, 0);
    [z, ~] = get_z(t, p);

    t = t - hours(9);  % convert from UTC to local time

    figure;
    subplot(2, 1, 1);
    plot(t, z);
    set(gca, 'ydir', 'reverse');
    ylabel('depth (m)');
    title(sprintf('HDPE, radius %.2f mm', r_pl*1000));
    xlim([t(1), t(end)]);

    subplot(2, 1, 2);
    subset_mask = (t > datetime(2016, 1, 20)) & (t < datetime(2016, 1, 20)+days(subset_days));
    plot(t(subset_mask), z(subset_mask));
    set(gca, 'ydir', 'reverse');
    ylabel('depth (m)');
    xlabel('local time (UTC-9)');
end


function ave_depth_for_different_mortalities()
%world map of zero depth contour, depending on various mortality values.
% the saved variables which are loaded in are generated by
% manually changing kooi_constants.m_A, then running ave_depth_seasons,
% and renaming the output.  Pretty sketchy, but that's why this folder is
% called "one-offs."

    fnames = {'mort_0.00.mat', 'mort_0.20.mat', 'mort_0.40.mat', 'mort_0.60.mat'};
    figure;
    for i=1:4
        load(fnames{i}, 'summer', 'spring', 'fall', 'winter', 'lat_grid', 'lon_grid', 'mortality_rate_per_day');
        yearly = (summer+spring+fall+winter)/4;  % this is ok because each vector has approx the same length
        [LAT, LON] = meshgrid(lat_grid, lon_grid);
        f = subplot(2, 2, i);
        m_proj('miller');
        [proj_LON, proj_LAT] = m_ll2xy(LON, LAT);
        [~, h] = contourf(proj_LON, proj_LAT, yearly);
        colormap(f, 'cool');
        set(h,'LineColor','none');
        m_coast();
        m_grid();
        title(sprintf('Mortality = %.2f per day', mortality_rate_per_day)); 
        caxis manual
        caxis([0 350]);
    end
    hp4 = get(subplot(2,2,4),'Position');
    h = colorbar('Position', [hp4(1)+hp4(3)+0.01  hp4(2)  0.02 hp4(2)+hp4(3)*2.1]);
    set(h, 'YDir', 'reverse' );
    ylabel(h, 'Depth (m)')
    sgtitle('Yearly Average Depth, .1mm HDPE particles');
    
    %resize
    subplot(2, 2, 4);
    set(gca, 'Position', [0.5, 0.0, 0.4, 0.5]);
    subplot(2, 2, 3);
    set(gca, 'Position', [0.05, 0.0, 0.4, 0.5]);
    subplot(2, 2, 2);
    set(gca, 'Position', [0.5, 0.45, 0.4, 0.5]);
    subplot(2, 2, 1);
    set(gca, 'Position', [0.05, 0.45, 0.4, 0.5]);
end

function plot_yearly_ave_depth()
    load('ave_depth_seasons.mat', 'winter', 'spring', 'summer', 'fall', 'lat_grid', 'lon_grid');
    f = figure;
    yearly = (winter+spring+summer+fall)/4; % this is ok because each vector has approx the same length
    [LAT, LON] = meshgrid(lat_grid, lon_grid);
    m_proj('miller');
    [proj_LON, proj_LAT] = m_ll2xy(LON, LAT);
    [~, h] = contourf(proj_LON, proj_LAT, yearly);
    colormap(f, 'cool');
    set(h,'LineColor','none');
    m_coast();
    m_grid();
    title('Yearly average particle depth (HDPE, .1mm)'); 
    h = colorbar();
    set(h, 'YDir', 'reverse' );
    ylabel(h, 'Depth (m)')
end

function ave_depth_seasons()
%world map of average depth
% for each simulated lat, lon,
%   perform get_z_ave.  Then plot this on a world map.
%   Save the results in a .mat file because this takes a while.
% 
% get_z_ave for 1 particle takes ~ 2 seconds.
% if we sample earth in 1 deg, we get 360*180=64800 points.
%   this means we have a 64800*2/3600 = 36 hour simulation.
% if we sample earth in 10 deg, we get 36*18=648 points.
%   this means we have a 648*2/60 = 21.6 minute simulation.

    lon_grid = linspace(-180, 180, 36);
    lat_grid = linspace(-90, 90, 18);
    summer = zeros(length(lon_grid), length(lat_grid));
    fall = zeros(length(lon_grid), length(lat_grid));
    winter = zeros(length(lon_grid), length(lat_grid));
    spring = zeros(length(lon_grid), length(lat_grid));
    for lon_idx=1:length(lon_grid)
        for lat_idx=1:length(lat_grid)
            nchar = fprintf("%.1f percent done", ((lon_idx-1)*length(lat_grid) + lat_idx) / (length(lat_grid)*length(lon_grid)) * 100);
            p = Particle(.1e-3, kooi_constants.rho_HDPE, 0, lat_grid(lat_idx), lon_grid(lon_idx), 0);
            [z_summer, z_fall, z_winter, z_spring] = get_z_ave(p);
            summer(lon_idx, lat_idx) = z_summer;
            fall(lon_idx, lat_idx) = z_fall;
            winter(lon_idx, lat_idx) = z_winter;
            spring(lon_idx, lat_idx) = z_spring;
            fprintf(repmat('\b', 1, nchar));  % matlab doesn't have carriage returns (ugh)
        end
    end

    %save('ave_depth_seasons.mat', 'p', 'lon_grid', 'lat_grid', 'summer', 'fall', 'winter', 'spring')
    mortality_rate_per_day = kooi_constants.m_A * constants.seconds_per_day;
    save('mort_0.60.mat', 'mortality_rate_per_day', 'p', 'lon_grid', 'lat_grid', 'summer', 'fall', 'winter', 'spring');
    
    figure;
    seasons = {winter, spring, summer, fall};
    names = {'DJF', 'MAM', 'JJA', 'OSN'};
    for i=1:4
        [LAT, LON] = meshgrid(lat_grid, lon_grid);
        f = subplot(2, 2, i);
        m_proj('miller');
        [proj_LON, proj_LAT] = m_ll2xy(LON, LAT);
        [~, h] = contourf(proj_LON, proj_LAT, seasons{i});
        colormap(f, 'cool');
        set(h,'LineColor','none');
        colorbar();
        m_coast();
        m_grid();
        xlabel('lon (deg E)');
        ylabel('lat (deg N)');
        title(names{i}); 
    end
end


function [summer, fall, winter, spring] = get_z_ave(p)
% do a 2-year simulation of particle vertical dynamics.
% Discard first year as spin-up, return average depth of each season of
% second year.  Skips time taken to begin settling.
    % p: the particle, whose properties determine lat, lon, density
    % returns: [summer, fall, winter, spring], all time-average depths (m)
    
    t = datetime(2015, 1, 1, 0, 0, 0):hours(.25*pi):datetime(2017, 1, 1, 0, 0, 0);
    p.update_particle_from_rho_tot(1024);  % start just when particle beginning to sink
    
    [z, ~] = get_z(t, p);
    if isnan(z)
        summer = nan;
        fall = nan;
        winter = nan;
        spring = nan;
        return;
    end
    
    z = z(year(t) == 2016);
    t = t(year(t) == 2016);
    mo = month(t);
    summer = mean(z(ismember(mo, [6,7,8])));
    fall = mean(z(ismember(mo, [9,10,11])));
    winter = mean(z(ismember(mo, [12,1,2])));
    spring = mean(z(ismember(mo, [3,4,5])));
end