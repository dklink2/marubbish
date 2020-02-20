function temperature = get_T(seek_lon, seek_lat, seek_z, seek_time)
%GET_T extract temperature from netcdf nearest to provided coordinates
%       seek_lon, seek_lat, seek_z can be vectors of length n, corresponding to
%       n coordinate pairs.  seek_time must be scalar.
    %seek_time: time (hours since 2000-01-01T00)
    %seek_lat: latitude (Deg N)
    %seek_lon: longitude (Deg E)
    %seek_z: depth (m, positive down)
    %returns: temperature (Celsius)
    temperature = index_hycom(Paths.temperature, 'water_temp', seek_lon, seek_lat, seek_z, seek_time);
end