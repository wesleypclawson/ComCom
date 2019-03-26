function [MI, HX, HY, PXY] = MutualInformation_Bin(sX, sY, tau)


%Sampling counts

PX=zeros(1,2);
PY=zeros(1,2);
PXY=zeros(2,2);

for t = max(1, 1-tau) : min(length(sX)-tau, length(sX))
    PX(sX(t)+1) = PX(sX(t)+1)+1;
    PY(sY(t+tau)+1) = PY(sY(t+tau)+1)+1;
    PXY(sX(t)+1, sY(t+tau)+1) = PXY(sX(t)+1, sY(t+tau)+1) + 1;
end

%Normalizing probabilities

PX = PX/sum(PX);
PY = PY/sum(PY);
PXY = PXY/sum(sum(PXY));

%Computing actually Mutual Info and entropies

HX = 0.0;
HY = 0.0;
MI = 0.0;

for u = 1:2
    if (PX(u) > 0.00001)
        HX = HX - PX(u)*log2(PX(u));
    end
end

for v = 1:2
    if (PY(v) > 0.00001)
        HY = HY - PY(v)*log2(PY(v));
    end
end


for u = 1:2
    for v = 1:2
        if (PXY(u,v) > 0.00001)
            MI = MI + PXY(u,v)*log2(PXY(u,v)/PX(u) / PY(v));
        end
    end
end

return
