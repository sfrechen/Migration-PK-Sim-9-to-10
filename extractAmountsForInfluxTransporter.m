clear all
clc
wdir = cd;

% add Matlab Toolbox to your Matlab Path

%% USER DEFINITIONS
% Define influx transporters to be evaluated
proteins = {'OATP1B1'};

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
            
            %% Fraction intracellular
            parameter = '*|Organism|*|Fraction intracellular';
            [f_cell,organs1] = getParameterValues(parameter,1,{'Liver'},1);
            
            %% Fraction interstitial
            parameter = '*|Organism|*|Fraction interstitial';
            [f_int,organs2] = getParameterValues(parameter,1,{'Liver'},1);
            if any(strcmp(organs1,organs2)==0)
                error('Organs mismatch!');
            end
            
            %% Interstitial Volume
            parameter = '*|Organism|*|Interstitial|Volume';
            [V_int,organs3] = getParameterValues(parameter,2,{'Liver'},1);
            if any(strcmp(organs1,organs3)==0)
                error('Organs mismatch!');
            end
            
            %% Plasma Volume
            parameter = '*|Organism|*|Plasma|Volume';
            [V_plasma,organs4] = getParameterValues(parameter,2,{'Liver',...
                'PortalVein','VenousBlood','ArterialBlood'},1);
            if any(strcmp(organs1,organs4)==0)
                error('Organs mismatch!');
            end
            
            %% Intracellular Volume
            parameter = '*|Organism|*|Intracellular|Volume';
            [V_cell,organs5] = getParameterValues(parameter,2,{'Liver'},1);
            if any(strcmp(organs1,organs5)==0)
                error('Organs mismatch!');
            end
            
            %% Organ Volume
            organs = organs1;
            V = getOrganVolume(organs);
            
            %% Protein Amount
            amount_int = zeros(length(organs),1);
            amount_plasma = amount_int;
            amount_cell = amount_int;
            for ii = 1:length(organs)
                try
                    amount_int(ii)=getParameter(['*|Organism|*' organs{ii} '|Interstitial|' protein '|Start amount'],1);
                end
                try
                    amount_plasma(ii)=getParameter(['*|Organism|*' organs{ii} '|Plasma|' protein '|Start amount'],1);
                end
                try
                    amount_cell(ii)=getParameter(['*|Organism|*' organs{ii} '|Intracellular|' protein '|Start amount'],1);
                end
            end
            
            %% Calculate "pseudo ammount" according to PK-Sim 9.1 (wrong) formulae:
            % ActiveInfluxSpecific_MM: CP(interstitial) * f_cell * V
            AMT1 = amount_int./V_int.*f_cell.*V;
            
            % BrainActiveInfluxFromPlasma_MM: CP(plasma) * f_int * V
            AMT2 = amount_plasma./V_plasma.*f_int.*V;
            idx_brain = find(contains(organs,'Brain'));
            
            % MucosaActiveInfluxFromLumen_MM: TM(intracellular)
            AMT3 = amount_cell;
            idx_mucosa = find(contains(organs,...
                {'Duodenum','UpperJejunum','LowerJejunum','UpperIleum','LowerIleum',...
                'Caecum','ColonAscendens','ColonTransversum','ColonDescendens',...
                'ColonSigmoid','Rectum'}));
            
            AMT(:,jj) = AMT1;
            AMT(idx_brain,jj) = AMT2(idx_brain);
            AMT(idx_mucosa,jj) = AMT3(idx_mucosa);
            
            kcat = getParameter(['*|*' protein '*|kcat'],1);
            
        else % PK-Sim 10
            %% Protein Amount
            amount_int = zeros(length(organs),1);
            amount_plasma = amount_int;
            amount_cell = amount_int;
            for ii = 1:length(organs)
                try
                    amount_int(ii)=getParameter(['*|Organism|*' organs{ii} '|Interstitial|' protein '|Start amount'],1);
                end
                try
                    amount_plasma(ii)=getParameter(['*|Organism|*' organs{ii} '|Plasma|' protein '|Start amount'],1);
                end
                try
                    amount_cell(ii)=getParameter(['*|Organism|*' organs{ii} '|Intracellular|' protein '|Start amount'],1);
                end
            end
            
            %% Calculate ammount according to PK-Sim 10 formulae:
            % ActiveInfluxSpecificInterstitialToIntracellular_MM: TM(interstitial)
            AMT1 = amount_int;
            
            % ActiveInfluxSpecificPlasmaToInterstitial_MM: TM(plasma)
            AMT2 = amount_plasma;
            idx_brain = find(contains(organs,'Brain'));
            
            % MucosaActiveInfluxFromLumen_MM: TM(intracellular)
            AMT3 = amount_cell;
            idx_mucosa = find(contains(organs,...
                {'Duodenum','UpperJejunum','LowerJejunum','UpperIleum','LowerIleum',...
                'Caecum','ColonAscendens','ColonTransversum','ColonDescendens',...
                'ColonSigmoid','Rectum'}));
            
            AMT(:,jj) = AMT1;
            AMT(idx_brain,jj) = AMT2(idx_brain);
            AMT(idx_mucosa,jj) = AMT3(idx_mucosa);
        end
    end
    AMT(isnan(AMT)) = 0;
    totAMT = sum(AMT);
    factor = totAMT(1)/totAMT(2);
    
    format long
    
    header = {'Organ','Amount PK-Sim 9','Amount PK-Sim 10','Ratio'};
    data = [header; [organs;'SUM';' ';'kcat'],...
        num2cell([AMT,AMT(:,1)./AMT(:,2);totAMT,factor;
        nan(1,3);
        kcat,kcat.*factor,factor])];
    
    
    xlswrite(fullfile(wdir,['CorrectionFactor_for_' protein '.xls']),data);
    disp([protein ' results exported to: ' wdir filesep 'CorrectionFactor_for_' protein '.xls']);
end
