classdef CalbetConstants
    %CalbetConstants contains (grazing) mortality rate constants from Calbet 2004
    
    properties (Constant)
        tropical_mortality = .50 / constants.seconds_per_day; % "tropical/subtropical" (s^-1)
        temperate_mortality = .41 / constants.seconds_per_day; % "temperate/subpolar" (s^-1)
        polar_mortality = .16 / constants.seconds_per_day; % "polar" (s^-1)
    end
    
    methods (Static)
        function m = getAlgaeMortality(lat)
            %getAlgaeMortality returns mortality value based on region
            % lat: latitude (Degrees N)
            % returns: regional algae mortality rate (s^-1)
            if abs(lat) < constants.subtropical_lat_max
                m = CalbetConstants.tropical_mortality;
            elseif abs(lat) < constants.arctic_circle_lat
                m = CalbetConstants.temperate_mortality;
            else
                m = CalbetConstants.polar_mortality;
            end
        end
    end
end

