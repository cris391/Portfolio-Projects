
-- bestmatch with weight setup
drop table if exists stack_wi;
create table stack_wi as
select id, tablename, lower(word) word from words
where word ~* '^[a-z][a-z0-9_]+$'
and tablename = 'posts' and (what='title' or what='body')
group by id,word,tablename;

DROP TABLE IF EXISTS weighted_wi;
CREATE TABLE weighted_wi(
id int, word text, document_term_count int, occurrences_of_term_in_document int, documents_containing_term int, tf numeric, idf numeric, tfidf numeric);

drop index if exists index_weighted;
create index index_weighted on weighted_wi(word);
drop index if exists index_weighted_id;
create index index_weighted_id on weighted_wi(id);

insert into weighted_wi (id, word, document_term_count, occurrences_of_term_in_document, documents_containing_term)
select stack_wi.id, stack_wi.word, t. document_term_count, t2.occurrences_of_term_in_document, t3.documents_containing_term from stack_wi,
(select id, count(*) document_term_count from stack_wi group by id) as t,
(select id, word, count(*) occurrences_of_term_in_document from stack_wi group by id, word) as t2,
(select word, count(*) documents_containing_term from words group by word) as t3
where stack_wi.id = t2.id and stack_wi.word = t2.word and stack_wi.id = t.id and stack_wi.word = t3.word;

drop function if exists relevanceOfDocumentToTerm();
create or replace function relevanceOfDocumentToTerm(questionid integer, term text)
returns numeric as $$
declare
	termFrequency numeric;
	inverseDocumentFrequency numeric;
	relevanceOfDocToTerm numeric;
	record record;
begin
for record in select distinct * from weighted_wi where id = questionid and word = term loop

	 termFrequency = log(1::numeric + (record.document_term_count::numeric / record.occurrences_of_term_in_document::numeric));
	 inverseDocumentFrequency = 1 / record.documents_containing_term::numeric;
	 relevanceOfDocToTerm = termFrequency * inverseDocumentFrequency;
end loop; 

	return relevanceOfDocToTerm;
end; $$
language 'plpgsql';

-- select * from relevanceOfDocumentToTerm(19, 'acos');

drop function if exists insertRelevance();
create or replace function insertRelevance()
returns void as $$
declare
	termFrequency numeric;
	inverseDocumentFrequency numeric;
	relevanceOfDocToTerm numeric;
	record record;
begin
for record in select * from weighted_wi loop
	 termFrequency = log(1::numeric + (record.document_term_count::numeric / record.occurrences_of_term_in_document::numeric));
	 inverseDocumentFrequency = 1 / record.documents_containing_term::numeric;
	 relevanceOfDocToTerm = termFrequency * inverseDocumentFrequency;
  update weighted_wi set tfidf=relevanceOfDocToTerm where id = record.id and word = record.word;
end loop; 
end; $$
language 'plpgsql';

select * from insertRelevance();