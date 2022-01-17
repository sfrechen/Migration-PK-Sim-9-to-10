clear all
clc
wdir = cd;

% add Matlab Toolbox to your Matlab Path

%% USER DEFINITIONS
% Define influx transporters to be evaluated
proteins = {'GABRG2','ATP1A2'};

% Define xml files from pk-sim 9.1 and from pk-sim 10
% XML simulation file exported from a pk-sim 9.1 snapshot file imported to pk-sim 9.1
xml_pksim9=fullfile(wdir,'Rifampicin_Midazolam v9.xml');
% XML simulation file exported from a pk-sim 9.1 snapshot file imported to pk-sim 10
xml_pksim10=fullfile(wdir,'Rifampicin_Midazolam v10.xml');


%% Analysis
xmllist = {xml_pksim9,xml_pksim10};

for pp = 1:length(proteins)
    protein = proteins{pp};
    for jj=1:2
        
        xml = xmllist{jj};
        % Initialize the simulation
        initSimulation(xml,'all','report','none');
        
        if jj == 1 % PK-Sim 9.1
            
            
            %% Interstitial Volume
            parameter = '*|Organism|*|Interstitial|Volume';
            [V_int,organs] = getParameterValues(parameter,2,{'Liver'},1);
            
            
            %% Protein Amount
            amount_int = zeros(length(organs),1);
            for ii = 1:length(organs)
                try
                    amount_int(ii)=getParameter(['*|Organism|*' organs{ii} '|Interstitial|' protein '|Start amount'],1);
                end
            end
            
            %% Get amount according to PK-Sim 9.1:
            AMT(:,jj) = amount_int;
            RefConc = getParameter(['*|*' protein '*|Reference concentration'],1);
            
        else % PK-Sim 10
            %% Protein Amount
            amount_int = zeros(length(organs),1);
            for ii = 1:length(organs)
                try
                    amount_int(ii)=getParameter(['*|Organism|*' organs{ii} '|Interstitial|' protein '|Start amount'],1);
                end
            end
            
            %% Get ammunt according to PK-Sim 10 :
            AMT(:,jj) = amount_int;
        end
    end
    AMT(isnan(AMT)) = 0;
    totAMT = sum(AMT);
    factor = totAMT(1)/totAMT(2);
    
    format long
    
    header = {'Organ','Amount PK-Sim 9','Amount PK-Sim 10','Ratio'};
    data = [header; [organs;'SUM';' ';'Reference concentration'],...
        num2cell([AMT,AMT(:,1)./AMT(:,2);totAMT,factor;
        nan(1,3);
        RefConc,RefConc.*factor,factor])];
    
    xlswrite(fullfile(wdir,['CorrectionFactor_for_' protein '.xls']),data);
    disp([protein ' results exported to: ' wdir filesep 'CorrectionFactor_for_' protein '.xls']);
end
