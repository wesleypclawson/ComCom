function Description = DL_Complexity(StateStream, Tol)

if (nargin < 2)
    Tol = 0.1;
end

N_modes = size(StateStream,1);
N_words = size(StateStream,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Coding into a symbol stream (with a small lossy compression)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SymbolStream = zeros(1,N_words);
for w = 1: N_words
    word = 0;
    for m = 1:N_modes
        lett = StateStream(m,w);
        word = word + power(10,m-1)*lett;
    end
    SymbolStream(w) = word;
end
Dictionary = unique(SymbolStream);
DictionarySize = length(Dictionary);
Freqs_Dictionary = zeros(DictionarySize,1);
for a = 1:length(Dictionary)
    Freqs_Dictionary(a) = sum(SymbolStream==Dictionary(a));
end
[~, idx] = sort(Freqs_Dictionary, 'descend');
PrefixStream = zeros(size(SymbolStream));
for a = 1:DictionarySize
    wo = find(SymbolStream == Dictionary(idx(a)));
    PrefixStream(wo) = a;
end

%Tolerate a small loss of Tol% trimming the less frequent words to denoise
k = 0; loss = 0;
while (loss < Tol)
    loss = 0;
    for l = 1:k
        loss = loss + k*length(find(Freqs_Dictionary == k))/N_words;
    end
    k = k+1;
end
%disp(['Merging words with less than ', num2str(k), ' appearances...'])
for a = 1:length(Dictionary)
    if(Freqs_Dictionary(a) < k)
        wo = find(PrefixStream == a);
        PrefixStream(wo) = -1;
    end
end
SymbolStream = PrefixStream;
Dictionary = unique(SymbolStream);
DictionarySize = length(Dictionary); %The new "lossy dictionary" may be shorter
Freqs_Dictionary = zeros(DictionarySize,1); % Freqs must be recomputed
for a = 1:length(Dictionary)
    Freqs_Dictionary(a) = sum(SymbolStream==Dictionary(a));
end
[~, idx] = sort(Freqs_Dictionary, 'descend');
PrefixStream = zeros(size(SymbolStream));
for a = 1:DictionarySize
    wo = find(SymbolStream == Dictionary(idx(a)));
    PrefixStream(wo) = a; %This should be a more compressed prefix stream
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the original and the description lengths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The original description is the dictionary plus a list of each character
% of the locations in which it appears. Overall it makes
%
%e.g. AAAAABBAAACCDDDB =
% = A(1)(2)(3)(4)(5)(8)(9)(10)B(6)(7)(16)C(11)(12)D(13)(14)(15) = 4+16 = 20

Original_Length = DictionarySize + N_words;

% Compress by suppressing repetitions, I enumerate only the first
% occurrence of a symbol and then use "pos-neg streaming" which requires
% shifts in Z, not in N
%
%e.g. AAAAABBAAACCDDDB =
% = A(5)(-2)(3)B(-5)(2)(-8)(1)C(-10)(2)D(-12)(3) = 15

Len = 0;
for a = 1:DictionarySize
    wo = (PrefixStream == a);
    Len = Len+1; %the Dictionary symbol itself
    position = 0;
    I_have_already_seen_it = 0;
    rubberspace = 0;
    blankrubberspace = 0;
    while(position < N_words)
        position = position+1;
        symbol = PrefixStream(position);
        if (~I_have_already_seen_it)
            if (symbol == a)
                I_have_already_seen_it = 1; %now I have seen it ;-)
                rubberspace = 1; %initiate a tubberspace to count how many times I see it
                if (blankrubberspace)
                    Len = Len +1; %add to Len the blankrubberspace that is over
                    blankrubberspace = 0; %and close the blank rubberspace
                end
            else
                if (~blankrubberspace)
                    %Len = Len + 1; %add a blank character... %UNCOMMENT IF
                    %WANT TO COUNT THE "-" AS SIGN
                    blankrubberspace = 1; %...and initiate a bank rubberspace
                else %if there is already a rubberspace...
                    blankrubberspace = blankrubberspace+1; %...continue to grow it!
                end
            end
        else % if I have already seen it
            if (symbol == a)
                rubberspace = rubberspace+1; %continue to grow the rubberspace
            else %if the symbol is not anymore the right one
                if (rubberspace) %if there was an open rubberspace...
                    rubberspace = 0; %... it is time to close it
                    Len = Len+1; %add it to the description
                    I_have_already_seen_it = 0; % and tell the reader head that it is as if I restarted
                else %if I have already seen it but there is not rubber space
                    disp('This should not happen!')
                end
            end
        end
    end
end

DLComp = Len / Original_Length;


%How many words could I have had?
PossibleWords = 1;
for m = 1: N_modes
    Alphabet = unique(StateStream(m,:));
    PossibleWords = PossibleWords*length(Alphabet);
end

RelDictSize = DictionarySize / PossibleWords;

Description.DLComp = DLComp;
Description.DictionarySize = DictionarySize;
Description.RelDictSize = RelDictSize;

%%%%%%%%%%%%%%%%