from squidtools import sqllm, util
import os

PROMPT = '''
Given a user comment, evaluate its stance toward the current US economy.
User comments are in response to news articles about the economy.
Definition
Stance toward the current US economy is defined as whether the commenter expresses a clear positive or negative evaluation of overall current or recent U.S. economic conditions (e.g., national growth, inflation, employment, prices, or general economic well-being).
POSITIVE comments must contain a claim that the overall U.S. economy is doing well. Examples include:
mentions of positive national economic indicators
personal or local experiences used as evidence of general economic improvement. The claim may be implicit when the comment is being used to respond to a parent comment or post title. 
direct descriptions of the economy as good, strong, healthy, improving, etc.
NEGATIVE comments must contain a claim that the overall U.S. economy is doing poorly. Examples include:
mentions of negative national economic indicators
personal or local hardships  used as evidence of national economic decline. The claim may be implicit when the comment is being used to respond to a parent comment or post title. 
direct descriptions of the economy as bad, weak, unhealthy, worsening, etc.
OTHER applies when no explicit claim about overall U.S. economic conditions is made. This includes:
commentary about politics, ideology, media narratives, hypocrisy, corruption, or culture
sarcasm that mocks political actors or common talking points without asserting economic conditions
discussions of individual policies (taxes, health care, minimum wage, ACA, job quality, inequality) unless the author directly generalizes them to national economic performance
local or personal anecdotes without an explicit national generalization
descriptive financial mechanics or market volatility without evaluation of overall economic conditions
comparisons involving other countries
historical claims without evaluating current conditions
Clarifications
Evaluative language about welfare, inequality, wealth distribution, or class conflict is OTHER unless the commenter explicitly states the U.S. economy overall is good or bad.
Sarcasm should be interpreted based on the underlying literal claim. If the literal content does not explicitly evaluate current national economic conditions, label as OTHER.
Output Format

Respond using JSON with the following keys:
- Reasoning - Explain your reasoning
- Stance - a classification (POSITIVE/NEGATIVE/OTHER) 

'''
sqllm.apply_files(
    infile='data/responses.tsv',
    outfile='data/responses.stance.tsv',
    config={
        'prompt': PROMPT,
        'key': 'ResponseId',
        'input_columns': ['comment_text'],
        'output_columns': ['Reasoning', 'Stance']
    }
)