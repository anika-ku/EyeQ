function P = retinaXSimulationParameters()
%RETINAXSIMULATIONPARAMETERS Editable district-level simulation defaults.
P.patientsPerYear = 100000;
P.workingDaysPerYear = 300;
P.operatingHoursPerDay = 8;
P.numCameras = 20;
P.imagesPerCameraPerHour = 8;
P.bandwidthMbps = 10;
P.imageSizeMB = 2.5;
P.aiWorkers = 4;
P.aiImagesPerHour = 60;
P.reviewers = 5;
P.reviewsPerHour = 12;
P.referableRatePercent = 18;
end
