clc;
clear;
addpath(genpath("./BP"));
epsilons = 0.05:0.05:0.5;
glob_iter = 2000;
pct_errs = epsilons;
m = 1;
for epsilon = epsilons
    desired_n = 100;
    l_max = 5;
    r_avg_max = 100;
    [n, k, L, R] = iLDPC(epsilon, desired_n, r_avg_max, l_max);
    if(n-k<l_max)
        continue
    end
    H = zeros(n-k, n);
    n_i = 1; 
    r = find(R);
    burnt_rows = [];
    burnt_cols = [];
    for i = 1:length(L)
        if (L(i) == 0)
            continue
        end

        for j = 1:L(i)
            H(1:i, n_i) = 1;
            if (i == n-k)
                burnt_cols = [burnt_cols, n_i];
            end
            n_i = n_i + 1;
        end
    end

    % fix up parity condition algorithm
    for i = 1:n-k
        if (~any(i == burnt_rows))
            for j = 1:n
                if(sum(H(i,:)) <= r)
                    break
                end
                if(~any(j == burnt_cols) && H(i,j) == 1)
                    H(i,j) = 0;
                    for t = i:n-k
                        if(~any(t == burnt_rows) && sum(H(t, :)) < r && H(t, j) == 0)
                            H(t, j) = 1;
                            if(sum(H(t, :)) == r)
                                burnt_rows = [burnt_rows, t];
                            end
                            break;
                        end
                    end
                end
            end
            burnt_rows = [burnt_rows, i];
            % find new burnt cols
            burnt_cols = 1:n;
            for j_2 = 1:n
                for i_2 = 1:n-k
                    if(~any(i_2 == burnt_rows) && sum(H(i_2,:)) < r && H(i_2, j_2) == 0)
                        burnt_cols(j_2) = 0;
                    end
                end
            end
            burnt_cols = nonzeros(burnt_cols);
        end
    end
    
    % mix up rows 
    H = H(randperm(n-k), :);

    % mix up cols
    H = H(:, randperm(n));
    
    H = sparse(H);
    msg = zeros(n, 1)';
    
    stat_iter = glob_iter/length(epsilons);
    pct_err = zeros(stat_iter, 1);
    
    parfor i = 1:stat_iter
        c_data = BEC(epsilon, msg);
        dec_data = bp_decode(H, c_data, 100);
        [~, pcterr_i] = biterr(msg, dec_data);
        pct_err(i) = pcterr_i;
    end
    pct_errs(m) = mean(pct_err);
    m = m + 1;
end

plot(epsilons, pct_errs);
xlabel('Channel erasure rate'); ylabel('Bit error rate');
title('iLDPC(999, 501) BER on BEC');