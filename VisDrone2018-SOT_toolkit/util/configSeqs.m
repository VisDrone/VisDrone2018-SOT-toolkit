function seqs = configSeqs(datasetPath)

d = dir(datasetPath);
isub = [d(:).isdir]; 
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,{'.','..'})) = [];

seqs = cell(1, length(nameFolds));
for i = 1:length(nameFolds)
    seq.name = nameFolds{i};
    seq.path = fullfile(datasetPath, nameFolds{i});
    seq.startFrame = 1;
    seq.endFrame = length(dir([seq.path '\img*.jpg']));
    seq.nz = 7;
    seq.ext = 'jpg';
    seq.init_rect = [0, 0, 0, 0];
    seqs{i} = seq;
end
