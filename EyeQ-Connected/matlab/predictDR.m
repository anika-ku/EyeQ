function [predictedLabel, classIdx, scores, sortedScores, sortedNames] = predictDR(net, img, classNames)
%PREDICTDR Run DR severity classification on a preprocessed fundus image.
%
%   [predictedLabel, classIdx, scores, sortedScores, sortedNames] = ...
%       predictDR(net, img, classNames)
%
%   Inputs:
%       net        - trained (or demo/untrained) DAGNetwork
%       img        - preprocessed RGB image matching the network input size
%       classNames - cell array of class-name strings, in the SAME order
%                    used when the network's head was created
%                    (Level 0 .. Level 4)
%
%   Outputs:
%       predictedLabel - name of the winning class
%       classIdx       - 1-based index of the winning class (1..5),
%                        i.e. DR level = classIdx - 1
%       scores         - 1x5 vector of softmax probabilities, in the
%                        network's own class order
%       sortedScores   - scores sorted descending
%       sortedNames    - corresponding class names, sorted descending

    if isa(net, 'dlnetwork')
        % Demo (untrained) network built via dlnetwork - classify() doesn't
        % work on dlnetwork objects, so run the forward pass manually. The
        % network graph still ends with a softmax ('prob') layer before
        % where the classification output layer used to be, so this
        % already returns probabilities, not raw logits.
        X = dlarray(single(img), 'SSCB');
        Y = predict(net, X);
        scores = reshape(extractdata(Y), 1, []);
        [sortedScores, order] = sort(scores, 'descend');
        sortedNames = classNames(order);
        [~, classIdx] = max(scores);
        predictedLabel = classNames{classIdx};
    else
        [predictedLabel, scores] = classify(net, img);
        [sortedScores, order] = sort(scores, 'descend');
        sortedNames = classNames(order);
        classIdx = find(strcmp(classNames, char(predictedLabel)), 1);
        if isempty(classIdx)
            [~, classIdx] = max(scores);
            predictedLabel = classNames{classIdx};
        end
    end
end
