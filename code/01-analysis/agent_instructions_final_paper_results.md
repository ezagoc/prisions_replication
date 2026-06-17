# Agent Instructions: Final Paper Results Integration

## Objective

Build the final version of the paper by editing the Overleaf project in `v4_draft`. The main task is to update the `results.tex` section so that it includes the final event-study figures, ATT tables, and corresponding text for the main results and mechanisms.

The current Overleaf draft has a `.tex` file that includes figures that are not currently present in this local version. For this pass, move the relevant figure and table calls into `results.tex` so that the results section directly includes the figures and tables discussed in the text.

This should be a low-risk finishing pass. Do not redesign the paper, do not change the empirical specifications, and do not add new robustness exercises unless required to generate the requested outcomes. The focus is on: outcome coverage, clean visualization, academic tables, consistent labels, correct Overleaf paths, and text that matches the results.

---

## General Requirements

### 1. Work inside the existing Overleaf structure

Use the current draft in `v4_draft` to determine:

- where the results subsections currently begin and end;
- where figures and tables should be placed relative to the prose;
- the existing figure/table numbering and labels;
- the current conventions for captions, notes, references, and appendix links.

Do not create a parallel results section. Edit the existing `results.tex` file.

### 2. Figure paths

All final figures should be called from the `results/` folder. Set paths accordingly in the LaTeX code.

Use a consistent convention such as:

```latex
\includegraphics[width=\textwidth]{../results/<figure_name>.pdf}
```

or the equivalent path format already used in the Overleaf project.

If the existing project defines a graphics path, check whether the path should be:

```latex
\includegraphics[width=\textwidth]{<figure_name>.pdf}
```

or

```latex
\includegraphics[width=\textwidth]{../results/<figure_name>.pdf}
```

The final code should compile without requiring manual path edits.

### 3. Event-study style

For all event-study plots, return to the point-and-confidence-interval format rather than the lineplot/ribbon format.

Use:

- points for estimated dynamic effects;
- vertical confidence intervals;
- a horizontal zero line;
- a vertical reference line at treatment timing if appropriate;
- clear x-axis title, such as `Years since prison opening` or the timing convention already used in the paper;
- clear y-axis title, such as `Estimated effect, with 95% confidence interval`.

Do not use overly technical titles in the plots. Move technical details to captions or notes.

### 4. Estimator

Use CSDID with controls for all main event-study plots unless otherwise noted.

For ATT tables, include:

- CSDID with controls.

Later in the Appendix we will add the other ones.

### 5. ATT table format

For each results block, create an academic regression-style ATT table with:

- outcomes as columns;
- one row for the ATT with controls;
- standard errors in brackets under each estimate;
- no significance stars;
- number of observations;
- controls indicator (`Yes`);
- concise notes explaining the estimator, standard errors, and outcome transformations.

Example structure:
```latex
\begin{table}[!htpb] \centering    \caption{ATT results using TWFE}    \label{tab:twfe_table}  \scriptsize  \begin{tabular}{@{\extracolsep{0pt}}lcccccccc}  \\[-1.8ex]\hline  \hline \\[-1.8ex]   & \shortstack{log Total \\ processed} & \shortstack{log Pre-trial \\ detention} & \shortstack{log Released} & \shortstack{log Total \\ sentenced} & \shortstack{log Not \\ guilty} & \shortstack{log Guilty \\ (prison)} & \shortstack{Time \\ sentenced} & \shortstack{log Guilty \\ (money)} \\  \\[-1.8ex] & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8)\\  \hline \\[-1.8ex]   Treat $\times$ Post & 0.082$^{***}$ & 0.068$^{***}$ & 0.023$^{***}$ & 0.073$^{***}$ & 0.029$^{***}$ & 0.069$^{***}$ & 0.018$^{**}$ & 0.021$^{***}$ \\    & (0.010) & (0.010) & (0.007) & (0.009) & (0.006) & (0.009) & (0.007) & (0.005) \\    & & & & & & & & \\  \hline \\[-1.8ex]  Municipality FEs & Yes & Yes & Yes & Yes & Yes & Yes & Yes & Yes \\  Time FEs & Yes & Yes & Yes & Yes & Yes & Yes & Yes & Yes \\  Mean of Control (Never Treated) & 11.025 & 9.135 & 1.195 & 8.504 & 0.887 & 7.309 & 0.66 & 0.263 \\  Observations & 191,646 & 191,646 & 191,646 & 191,646 & 191,646 & 191,646 & 191,646 & 191,646 \\  R$^{2}$ & 0.857 & 0.848 & 0.721 & 0.847 & 0.695 & 0.842 & 0.425 & 0.621 \\  \hline  \hline \\[-1.8ex]  \multicolumn{9}{l} {\parbox[t]{16cm}{ \textit{Notes:}
Effect of the contruction of a federal prison on a 300km vicinity of a municipality on different sentencing outcomes.}} \\ \end{tabular}  \end{table} 

```
Adapt it but always use R code to generate it. Do not use asterixs for significance.

### 6. Text updates

After adding each table or figure, update the surrounding results text so that:

- the claims match the displayed estimates;
- outcome names match the table and figure labels;
- references to figures and tables use the correct `\ref{}` labels;
- the interpretation remains cautious and academic;
- the text distinguishes clearly between arrests/pre-trial outcomes and sentencing outcomes.

Do not overstate effects. When describing mechanisms, use language such as “consistent with,” “suggests,” or “appears to be driven by,” unless the design directly supports a stronger causal statement.

---

# Main Results

## A. Rename “Pre-trial phase” to “Arrests”

In the results section, change the subsection title from:

```latex
Pre-trial phase
```

to:

```latex
Arrests
```

The motivation is that the key outcome currently labeled `Total Processed` should be presented as arrests. Throughout the results section:

- replace `Total Processed` with `Arrests`;
- replace `log(Total Processed)` with `log(Arrests)`;
- keep `Pre-trial Detention` and `Released` as separate outcomes.

Use consistent capitalization:

- `Arrests`
- `Pre-trial Detention`
- `Released`

## B. Arrests event-study figure

Create a main-text event-study figure using CSDID with controls for:

1. `log(Total Processed)` renamed as `log(Arrests)`;
2. `log(Pre-trial Detention)`;
3. `log(Released)`.

### Preferred visualization

Use one combined figure with three panels rather than placing all three outcomes on the same axis.

Recommended layout:

- Panel A: `log(Arrests)`
- Panel B: `log(Pre-trial Detention)`
- Panel C: `log(Released)`

This avoids clutter while keeping the outcomes directly comparable. Use the same y-axis scale only if doing so does not compress one of the outcomes too much. If scales differ, make that clear through the panel axes.

Avoid using different colored lines on the same graph if confidence intervals overlap heavily. A faceted/panel figure is preferable for readability in the paper.

### LaTeX label

Use a label such as:

```latex
\label{fig:es_arrests_main}
```

### Caption draft

```latex
\caption{Dynamic effects of prison openings on arrests}
```

### Note draft

```latex
\emph{Notes:} The figure reports CSDID event-study estimates with controls. Points denote dynamic treatment effects and vertical bars report 95 percent confidence intervals. The outcome labeled `Arrests' corresponds to the log of total processed individuals in the original data.
```

## C. Arrests ATT table

Create an ATT table for the arrests outcomes with and without controls.

Columns:

1. `log(Arrests)`
2. `log(Pre-trial Detention)`
3. `log(Released)`

Rows:

- ATT, no controls;
- standard errors in brackets;
- observations;
- pure control mean.

Do not include significance stars.

### LaTeX label

Use:

```latex
\label{tab:att_arrests}
```

### Table title

```latex
\caption{Average treatment effects on arrests}
```

## D. Update arrests text

Update the text around the arrests figure and table to say that prison openings increase arrests, pre-trial detention, and releases. Make sure the text reflects the actual ATT magnitudes once the table is populated.

Suggested structure:

1. Begin with the event-study evidence.
2. Then discuss the ATT table.
3. Explain that the increase in releases helps distinguish a pure detention-capacity story from a broader increase in processing/arrests.
4. Avoid saying the results mechanically imply more crime; the interpretation should be that additional prison capacity is associated with a larger flow of people through the criminal justice system.

---

# Sentencing Results

## A. Sentencing event-study outcomes

Create event-study plots using CSDID with controls for the following outcomes:

1. `log(Total Sentenced)`
2. `log(Guilty (Prison))`
3. `log(Guilty (Money))`
4. `log(Not Guilty)`
5. `Time Sentenced`
6. `log(Time Sentenced)`

For `log(Time Sentenced)`, handle zeros carefully. Use a transformation that is transparent and appropriate for zero values. The preferred option is:

```text
log(1 + Time Sentenced)
```

Label this outcome as:

```text
log(1 + Sentence Length)
```

or, if the paper uses “Time Sentenced” consistently:

```text
log(1 + Time Sentenced)
```

Do not use a denominator-based transformation unless the existing code already defines one clearly. If the current code says “considering 0 in the denom,” implement the transformation so that zero sentence lengths remain defined and document the transformation in the figure/table notes.

## B. Sentencing figure presentation

Do not place all six outcomes in a single crowded plot.

Preferred main-text layout:

### Figure 1: Sentencing decisions

Include four panels:

- Panel A: `log(Total Sentenced)`
- Panel B: `log(Guilty (Prison))`
- Panel C: `log(Guilty (Money))`
- Panel D: `log(Not Guilty)`

Use label:

```latex
\label{fig:es_sentencing_decisions}
```

Caption:

```latex
\caption{Dynamic effects of prison openings on sentencing decisions}
```

### Figure 2: Sentence length

Include two panels:

- Panel A: `Sentence Length`
- Panel B: `log(1 + Sentence Length)`

Use label:

```latex
\label{fig:es_sentence_length}
```

Caption:

```latex
\caption{Dynamic effects of prison openings on sentence length}
```

This separates sentencing outcomes from sentence length outcomes and avoids clutter.

## C. Sentencing ATT table

Create an ATT table with and without controls for:

1. `log(Total Sentenced)`
2. `log(Guilty (Prison))`
3. `log(Guilty (Money))`
4. `log(Not Guilty)`
5. `Sentence Length`
6. `log(1 + Sentence Length)`

Use the same regression-style format as the arrests table:

- estimates;
- standard errors in brackets;
- no stars;
- observations;
- Pure control outcome mean

Use `\shortstack{}` where needed to keep columns readable.

Suggested labels:

```latex
\label{tab:att_sentencing}
```

Suggested caption:

```latex
\caption{Average treatment effects on sentencing outcomes}
```

## D. Update sentencing text

Update the text to match the estimates in the figures and table.

The text should distinguish among:

- the extensive margin of sentencing: `Total Sentenced`;
- the type of sentence: `Guilty (Prison)`, `Guilty (Money)`, `Not Guilty`;
- the intensity of punishment: `Sentence Length`.

Use the actual table estimates to avoid overstating the findings. If the strongest results are for guilty prison sentences and not monetary sentences, say so clearly. If sentence length is noisy or small, describe it cautiously.

---

# Mechanisms

Create a separate mechanisms subsection inside Results.

The mechanisms section should examine whether the increase in arrests appears to be driven by:

1. low-level crimes;
2. arrests of marginalized individuals;
3. short-sentence/petty-offense categories rather than high-sentence serious offenses.

The mechanism discussion should be framed as evidence on composition.

---

## A. Arrests by type of crime

### Argument to develop

Add results showing that the increase in arrests is mostly driven by low-level crimes such as:

- Property Crimes;
- Bodily Injury and Physical Harm.

At the same time, tougher crimes such as:

- Homicides

remain largely unchanged, while crimes that began to be pursued more directly at the federal level, such as:

- Drugs;
- Guns

decrease.

Use careful language:

```text
The composition of the increase is consistent with the interpretation that expanded prison capacity increased enforcement or processing primarily for lower-level offenses, rather than reflecting an increase in serious violent crime.
```

### Main event-study figure

Create a compact CSDID-with-controls event-study figure in the main text for the four most important crime categories:

1. Property Crimes;
2. Bodily Injury;
3. Physical Harm;
4. Homicides.

Preferred visualization:

- same figure different colors, desfazados;
- point estimates with 95 percent confidence intervals;
- same event-study style as the main figures.

Use label:

```latex
\label{fig:es_crime_type_main}
```

Caption:

```latex
\caption{Dynamic effects of prison openings on arrests by type of crime}
```

### ATT table for all crime categories

Create an ATT table that includes all crime categories, not only the four shown in the main figure.

The table should include at least:

- Property Crimes;
- Bodily Injury;
- Physical Harm;
- Homicides;
- Drugs;
- Guns;
- any other crime categories available in the current results folder/code.

Use with-controls. If the table becomes too wide, split it into two panels or two tables:

- Panel A: low-level and bodily-harm offenses;
- Panel B: serious, federalized, or other offenses.

Use label:

```latex
\label{tab:att_crime_type}
```

Caption:

```latex
\caption{Average treatment effects on arrests by type of crime}
```

### Appendix event studies

Move the remaining crime-type event studies to the appendix in a compact format.

Recommended appendix layout:

- multi-panel figures, four to six outcomes per figure;
- consistent event-study style;
- one common caption explaining that these are CSDID-with-controls estimates;
- clear panel labels.

Use labels such as:

```latex
\label{fig:app_es_crime_type_all_1}
\label{fig:app_es_crime_type_all_2}
```

---

## B. Arrests of marginalized individuals

### Argument to develop

Add results showing that the increase in arrests is concentrated among marginalized individuals. Define marginalized status using the available categories:

Suggested wording:

```text
The increase in arrests is concentrated among individuals with lower levels of schooling, individuals without employment, and younger defendants. This composition is consistent with the interpretation that expanded prison capacity increased the processing of more socially vulnerable defendants.
```

### Figures to include

Include both:

1. an event-study graph for total arrests by marginalized status;
2. an event-study graph for pre-trial detention by marginalized status.

Use CSDID with controls.

Preferred visualization:

- one figure for arrests;
- one figure for pre-trial detention;
- each figure should use panels for the categories rather than overlaying too many groups on one axis.

Suggested labels:

```latex
\label{fig:es_marginalized_arrests}
\label{fig:es_marginalized_pretrial}
```

Suggested captions:

```latex
\caption{Dynamic effects of prison openings on arrests of marginalized individuals}
\caption{Dynamic effects of prison openings on pre-trial detention of marginalized individuals}
```

### ATT table

Create an ATT table including all marginalized-status categories available.

Use label:

```latex
\label{tab:att_marginalized}
```

Caption:

```latex
\caption{Average treatment effects by defendant socioeconomic status}
```

---

## C. Sentencing by sentence-length categories

### Argument to develop

Add sentencing-composition results showing that the increase appears to be driven by petty or low-sentence crimes.

The main interpretation should be:

- increases are concentrated in short-sentence categories;
- there is no comparable increase for more serious offenses;
- the number of sentenced individuals with high sentences may decrease;
- this supports the interpretation that expanded capacity increased the processing of lower-level offenses rather than increasing punishment for serious crime.

Use cautious wording:

```text
The sentencing composition suggests that the additional arrests and convictions are concentrated among lower-sentence cases. This pattern is consistent with an increase in the processing of petty or lower-level offenses, rather than a broad increase in serious criminal convictions.
```

### Main sentencing-composition figure

Include the first two sentence-length categories and the last category in the same main-text figure.

For example, if the categories are ordered from lowest to highest sentence length:

- Category 1: lowest sentence category;
- Category 2: second-lowest sentence category;
- Last category: highest sentence category.

Preferred visualization:

- overlaid plot;
- points and 95 percent confidence intervals;
- CSDID with controls.

Use label:

```latex
\label{fig:es_sentence_categories_main}
```

Caption:

```latex
\caption{Dynamic effects of prison openings by sentence-length category}
```

### ATT table

Create an ATT table including all sentence-length categories.

Use label:

```latex
\label{tab:att_sentence_categories}
```

Caption:

```latex
\caption{Average treatment effects by sentence-length category}
```

The table should allow the reader to see whether estimates are larger for low-sentence categories and smaller, null, or negative for high-sentence categories.

---

# Labeling Conventions

Use clear, reader-facing labels.

## Replace technical variable names

Use these labels in figures, tables, captions, and text:

| Original / technical label | Final label |
|---|---|
| `Total Processed` | `Arrests` |
| `log(Total Processed)` | `log(Arrests)` |
| `Pretrial Detention` / `Pre-trial detention` | `Pre-trial Detention` |
| `Guilty prison` | `Guilty (Prison)` |
| `Guilty money` | `Guilty (Money)` |
| `Not guilty` | `Not Guilty` |
| `Time sentenced` | `Sentence Length` or `Time Sentenced`, but use one consistently |
| `log(Time Sentenced)` | `log(1 + Sentence Length)` if zero-adjusted |

Use `\shortstack{}` in LaTeX table headers when labels are long.

Examples:

```latex
\shortstack{log(Pre-trial\\Detention)}
\shortstack{log(Guilty\\(Prison))}
\shortstack{log(1 +\\Sentence Length)}
```

---

# LaTeX Integration Checklist

For every new figure or table:

1. Add the figure/table to `results.tex`.
2. Place it near the paragraph that discusses it.
3. Add a clear caption.
4. Add a stable label.
5. Reference it in the text using `Figure~\ref{...}` or `Table~\ref{...}`.
6. Check that the file path points to the `results/` folder.
7. Check that the figure/table compiles in Overleaf.
8. Check that labels are not duplicated.
9. Check that appendix figures are referenced from the main text if they support a claim.
10. Check that all text claims correspond to displayed estimates.

---

# Suggested Results Section Structure

The final `results.tex` should approximately follow this structure:

```latex
\section{Results}

\subsection{Arrests}

% Event-study figure: arrests, pre-trial detention, released
% ATT table: arrests outcomes
% Text updated to interpret both the dynamic estimates and ATT estimates

\subsection{Sentencing}

% Event-study figure: sentencing decisions
% Event-study figure: sentence length
% ATT table: sentencing outcomes
% Text updated to distinguish sentencing margins

\subsection{Mechanisms}

\subsubsection{Arrests by Type of Crime}

% Main four-panel crime-type figure
% ATT table with all crime categories
% Appendix reference for remaining crime-type event studies

\subsubsection{Arrests of Marginalized Individuals}

% Total arrests figure by marginalized status
% Pre-trial detention figure by marginalized status
% ATT table for all marginalized categories

\subsubsection{Sentencing Composition}

% Main sentence-category figure with first two and last categories
% ATT table with all sentence-length categories
% Text linking low-sentence categories to petty/low-level offense interpretation
```

Adapt subsection titles to match the current draft style if needed, but preserve this ordering.

---

# Appendix Requirements

Move secondary event studies to the appendix instead of crowding the main results section.

Appendix figures should include:

- all remaining crime-type event studies not shown in the main text;
- any additional marginalized-status categories not shown in the main text;
- all sentence-length categories not shown in the main text if the main figure only includes selected categories.

Use compact multi-panel figures, with clear captions and consistent labels.

---

# Final Quality-Control Checklist

Before finishing, confirm that:

- `results.tex` compiles in Overleaf;
- all requested figures are included or explicitly noted as unavailable;
- all requested ATT tables are included;
- all event studies use point estimates and confidence intervals, not line/ribbon plots;
- all main event-study plots use CSDID with controls;
- all ATT tables include both with-controls and without-controls estimates;
- no ATT table uses significance stars;
- all standard errors appear in brackets;
- all figures use readable labels;
- `Total Processed` has been relabeled as `Arrests`;
- `Pre-trial phase` has been renamed to `Arrests`;
- figure paths point to the `results/` folder;
- the prose refers to the correct figure/table labels;
- the text does not overstate the mechanism evidence;
- appendix figures are referenced where appropriate;
- there are no duplicated LaTeX labels;
- the final paper remains consistent with the existing draft structure.

---

# Deliverables

The agent should deliver:

1. updated `results.tex`;
2. any new or revised LaTeX table files, if tables are stored separately;
3. final main-text figures saved in the `results/` folder;
4. appendix figures saved in the appropriate appendix/results folder;
5. a short change log listing:
   - figures added;
   - tables added;
   - labels changed;
   - text sections updated;
   - any requested output that could not be generated because the source file or estimate was unavailable.
