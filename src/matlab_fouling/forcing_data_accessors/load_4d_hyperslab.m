function slab = load_4d_hyperslab(dataset_path, variable_name, lon_range, lat_range, z_range, time_range)
%LOAD_HYPERSLAB extracts a hyperslab of the provided variable from the
%               provided netcdf dataset, given ranges of lon, lat, z, and time
%       the range variables are of form [min_value, max_value]
%       The ranges will be matched to the nearest values along each dimension
%   dataset_path: absolute path to a netcdf dataset with dimensions (lon, lat, depth, time)
%   variable_name: name of the variable to extract
%   lon_range: min/max longitude (Deg E)
%   lat_range: min/max latitude (Deg N)
%   z_range: min/max depth (m, positive down)
%   time_range: min/max time (Matlab datetime object)
%   returns: a hyperslab object

    lon_range = mod(lon_range, 360);  % make negative lons positive
    time_range = hours(time_range - datetime(2000, 01, 01, 00, 00, 00));  % convert to format stored in netcdf: hours since 2000-01-01T00:00:00
    
    ncid = dataset_path;
    lon = ncread(ncid, 'lon');
    lat = ncread(ncid, 'lat');
    z = ncread(ncid, 'depth');
    time = ncread(ncid, 'time');
    
    [~, lon_idx] = min(abs(lon-lon_range));
    [~, lat_idx] = min(abs(lat-lat_range));
    [~, z_idx] = min(abs(z-z_range));
    [~, time_idx] = min(abs(double(time)-time_range));
    
    data = ncread(ncid, variable_name, ...
        [lon_idx(1),        lat_idx(1),  ...        % start indices
            z_idx(1),           time_idx(1)], ...
        [lon_idx(2)-lon_idx(1)+1, lat_idx(2)-lat_idx(1)+1, ...  % end indices
            z_idx(2)-z_idx(1)+1,  time_idx(2)-time_idx(1)+1]);
    
    lon = lon(lon_idx(1):lon_idx(2));
    lat = lat(lat_idx(1):lat_idx(2));
    z = z(z_idx(1):z_idx(2));
    time = time(time_idx(1):time_idx(2));
    time = time/24 + datenum('2000-01-01');  % convert to matlab datenum (days since year 0)
    
    slab = Hyperslab(lon, lat, z, time, data);
end