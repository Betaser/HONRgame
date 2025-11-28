import matplotlib.pyplot as plt
import numpy as np

LEN = 1.5
xs = np.linspace(0, LEN, 200)
norm_xs = []
ys = []
time_effect = 0.6
for x in xs:
    norm_x = x / LEN
    norm_xs.append(norm_x)
    norm_x -= time_effect
    if norm_x < 0:
        norm_x += 1
    ys.append(norm_x)
plt.plot(norm_xs, ys)
plt.show()

def wiggly():
    LEN = 1.5
    xs = np.linspace(0, LEN, 200)
    ys = []
    # Suppose length is arbitrary off screen; 1.5 ~= (sqrt 2)
    PD = 0.02
    N_PD = float(int(LEN / PD))
    print(N_PD)

    pds = []
    for i in range(1, int(N_PD) + 1):
        norm = i / int(N_PD)
        pd = 1 - pow((1 - norm), 2)
        print(pd)
        pds.append(pd)

    for i in range(int(N_PD)):
        pds[i] /= pds[int(N_PD) - 1]
        print(pds[i])

    for x in xs:
        norm_x = x / LEN

        # Calc pdi and stuff ourselves
        pdi = 0
        lower = 0
        upper = pds[0]
        while upper < norm_x:
            pdi += 1
            lower = upper
            upper = pds[pdi]

        # n_pd = float(int(LEN / pds[pdi]))

        # print(f"norm_x {norm_x} lower {lower} upper {upper}", end="")
        if pdi % 2 == 1:
            y = 1 / (upper - lower) * pow(norm_x - lower, 2) + lower 
            # print("+")
        else:
            y = -1 / (upper - lower) * pow(norm_x - upper, 2) + upper
            # print("-")
        y *= LEN
        ys.append(y)

    plt.plot(xs, ys)
    plt.show()