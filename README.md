# Migration-PK-Sim-9-to-10

The migration to PK-Sim 10 changes all interstitially expressed amounts of proteins in order to consistently use the tissue volume as what was originally termed in PK-Sim 9 the `Volume of protein container`.

Two Matlab scripts are presented to derive a POTENTIAL correction factor for affected proteins when migrating PK-Sim 9 models to PK-Sim 10 models (via the [Snapshot](https://docs.open-systems-pharmacology.org/working-with-pk-sim/pk-sim-documentation/importing-exporting-project-data-models#exporting-project-to-snapshot-loading-project-from-snapshot) functionality).
The derived factors represent the ralationship of the overal body amount of the protein expressed in interstitial space in PK-Sim 9 in comparison to PK-Sim 10 and might be applied to the related `kcat`, `Specific Clearance`, `Reference Concentration`, etc. (depending on the needs and preferences of the respective model).
It must be noted, that the application of the proposed factor does not warrant that the behaviour of the model is the same between the two versions. This must be checked by expert assessment. Further stepts to preserve model integrity might be necessary.

The two Matlab scripts require the latest Matlab Toolbox in the Matlab PATH environment, available for example [here](https://github.com/Open-Systems-Pharmacology/Reporting-Engine/releases/latest).

Script 1 `extractAmountsForInterstitialProteins.m` is applicable in general for interstitially expressed proteins (except influx transporters).
Script 2 `extractAmountsForInfluxTransporter.m` is applicable specifically for influx transporters (such as OATP1B1, etc.).

## Workflow

1. Start (portable) [PK-Sim 9](https://github.com/Open-Systems-Pharmacology/PK-Sim/releases/download/v9.1/pk-sim-portable-setup.zip) in developer mode. Open cmd in Windows, go to the PK-Sim 9 directory and execute `pksim /dev`.
2. Open your model project file and select a representative simulation.
3. Right click and `Export for Matlab/R...` as an `xml` file, e.g. <simulation pksim 9.xml>
4. Click on `File`, then `Export to Snapshot` and save the snapshot file.
5. Start (portable) [PK-Sim 10](https://github.com/Open-Systems-Pharmacology/PK-Sim/releases/download/v10.0.257/pk-sim-portable-setup.10.0.257.zip) in developer mode. Open cmd in Windows, go to the PK-Sim 10 directory and execute `pksim /dev`. 
6. Click on `File`, then `Load from Snapshot` and choose the previously saved snapshot file.
7. Choose the same simulation as before, tight click and `Export for Matlab/R...` as an `xml` file, e.g. <simulation pksim 10.xml>
8. Open Matlab and put the Matlab Toolbox to the Matlab PATH environment.
9. Fill the header of the respective script `extractAmountsForInterstitialProteins.m` or `extractAmountsForInfluxTransporter.m`:
- `proteins` provide an array of the proteins (as named in the indvidual building block of the simulation) to be analyzed
- `xml_pksim9` provide the pathe to the xml file from step 3
- `xml_pksim10` provide the pathe to the xml file from step 7
10. You will receive an excel file for each protein giving a comparison for each organ and proposal for a correction factor in the last line.

## Diclaimer
The scripts are neither official part of the Open System Pharmacology Suite nor have been subject to quality check. Please use with caution when migrating models.

